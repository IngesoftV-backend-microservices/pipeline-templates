#!/bin/bash

#################################################################################
# Script de Rollback Automatizado
#
# Este script facilita el rollback de un microservicio a una versión anterior
# en ambientes de desarrollo o producción.
#
# Uso:
#   ./rollback-service.sh <service-name> <environment> <target-version>
#
# Ejemplo:
#   ./rollback-service.sh user-service prod v1.2.0
#
# Autor: DevOps Team
# Fecha: 2024-11-29
#################################################################################

set -e  # Exit on error

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Función para imprimir mensajes
print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_header() {
    echo -e "\n${BLUE}========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}========================================${NC}\n"
}

# Función para validar parámetros
validate_params() {
    if [ $# -ne 3 ]; then
        print_error "Número incorrecto de parámetros"
        echo ""
        echo "Uso: $0 <service-name> <environment> <target-version>"
        echo ""
        echo "Parámetros:"
        echo "  service-name    : Nombre del microservicio (ej: user-service)"
        echo "  environment     : Ambiente (dev o prod)"
        echo "  target-version  : Versión objetivo para rollback (ej: v1.2.0)"
        echo ""
        echo "Ejemplo:"
        echo "  $0 user-service prod v1.2.0"
        exit 1
    fi

    SERVICE_NAME=$1
    ENVIRONMENT=$2
    TARGET_VERSION=$3

    # Validar environment
    if [[ ! "$ENVIRONMENT" =~ ^(dev|prod)$ ]]; then
        print_error "Environment debe ser 'dev' o 'prod'"
        exit 1
    fi

    # Validar formato de versión
    if [[ ! "$TARGET_VERSION" =~ ^v[0-9]+\.[0-9]+\.[0-9]+(-dev)?$ ]]; then
        print_error "Target version debe seguir formato vX.Y.Z o vX.Y.Z-dev"
        exit 1
    fi

    # Validar consistencia de environment y versión
    if [[ "$ENVIRONMENT" == "dev" ]] && [[ ! "$TARGET_VERSION" =~ -dev$ ]]; then
        print_warning "La versión $TARGET_VERSION no tiene sufijo -dev para ambiente dev"
        read -p "¿Desea continuar? (y/n): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    fi

    if [[ "$ENVIRONMENT" == "prod" ]] && [[ "$TARGET_VERSION" =~ -dev$ ]]; then
        print_error "No se puede usar versión de desarrollo (-dev) en producción"
        exit 1
    fi
}

# Función para verificar prerequisitos
check_prerequisites() {
    print_header "Verificando Prerequisitos"

    # Verificar kubectl
    if ! command -v kubectl &> /dev/null; then
        print_error "kubectl no está instalado"
        exit 1
    fi
    print_success "kubectl encontrado"

    # Verificar az CLI
    if ! command -v az &> /dev/null; then
        print_error "Azure CLI no está instalado"
        exit 1
    fi
    print_success "Azure CLI encontrado"

    # Verificar autenticación con Azure
    print_info "Verificando autenticación con Azure..."
    if ! az account show &> /dev/null; then
        print_error "No está autenticado con Azure"
        print_info "Ejecute: az login"
        exit 1
    fi
    print_success "Autenticado con Azure"
}

# Función para configurar variables según ambiente
setup_environment() {
    print_header "Configurando Ambiente: $ENVIRONMENT"

    if [ "$ENVIRONMENT" == "dev" ]; then
        NAMESPACE="ecommerce-dev"
        ACR_NAME="acrvingesoftdev"
        AKS_CLUSTER="aks-ecommerce-dev"
        AKS_RG="rg-ecommerce-microservices-dev"
    else
        NAMESPACE="ecommerce-prod"
        ACR_NAME="acrvingesoftprod"
        AKS_CLUSTER="aks-ecommerce-prod"
        AKS_RG="rg-ecommerce-microservices-prod"
    fi

    ACR_LOGIN_SERVER="${ACR_NAME}.azurecr.io"

    print_info "Namespace: $NAMESPACE"
    print_info "ACR: $ACR_LOGIN_SERVER"
    print_info "AKS Cluster: $AKS_CLUSTER"
    print_info "Resource Group: $AKS_RG"
}

# Función para obtener versión actual
get_current_version() {
    print_header "Obteniendo Versión Actual"

    CURRENT_IMAGE=$(kubectl get deployment $SERVICE_NAME -n $NAMESPACE -o jsonpath='{.spec.template.spec.containers[0].image}' 2>/dev/null || echo "")

    if [ -z "$CURRENT_IMAGE" ]; then
        print_error "No se pudo obtener la imagen actual del deployment $SERVICE_NAME"
        print_info "Verifique que el deployment existe en el namespace $NAMESPACE"
        exit 1
    fi

    CURRENT_VERSION=$(echo $CURRENT_IMAGE | awk -F':' '{print $2}')

    print_info "Imagen actual: $CURRENT_IMAGE"
    print_info "Versión actual: $CURRENT_VERSION"

    if [ "$CURRENT_VERSION" == "$TARGET_VERSION" ]; then
        print_warning "La versión actual ya es $TARGET_VERSION. No se requiere rollback."
        exit 0
    fi
}

# Función para verificar que la versión objetivo existe en ACR
verify_target_version() {
    print_header "Verificando Versión Objetivo en ACR"

    print_info "Buscando $SERVICE_NAME:$TARGET_VERSION en $ACR_NAME..."

    # Login a ACR
    az acr login --name $ACR_NAME > /dev/null 2>&1

    # Verificar que la imagen existe
    if ! az acr repository show-tags --name $ACR_NAME --repository $SERVICE_NAME --output table | grep -q "$TARGET_VERSION"; then
        print_error "La versión $TARGET_VERSION no existe en ACR para $SERVICE_NAME"
        print_info "Versiones disponibles:"
        az acr repository show-tags --name $ACR_NAME --repository $SERVICE_NAME --orderby time_desc --output table | head -10
        exit 1
    fi

    print_success "Versión $TARGET_VERSION encontrada en ACR"
}

# Función para crear backup del estado actual
create_backup() {
    print_header "Creando Backup del Estado Actual"

    BACKUP_DIR="/tmp/rollback-backup-$(date +%Y%m%d-%H%M%S)"
    mkdir -p $BACKUP_DIR

    print_info "Guardando deployment actual..."
    kubectl get deployment $SERVICE_NAME -n $NAMESPACE -o yaml > "$BACKUP_DIR/${SERVICE_NAME}-deployment.yaml"

    print_info "Guardando configuración actual..."
    kubectl get configmap -n $NAMESPACE -l app=$SERVICE_NAME -o yaml > "$BACKUP_DIR/${SERVICE_NAME}-configmaps.yaml" 2>/dev/null || true

    print_success "Backup guardado en: $BACKUP_DIR"
    echo "$BACKUP_DIR" > /tmp/last-rollback-backup.txt
}

# Función para obtener credenciales de AKS
get_aks_credentials() {
    print_header "Obteniendo Credenciales de AKS"

    print_info "Configurando kubectl para cluster $AKS_CLUSTER..."
    az aks get-credentials --resource-group $AKS_RG --name $AKS_CLUSTER --overwrite-existing > /dev/null

    print_success "Credenciales de AKS configuradas"
}

# Función para ejecutar rollback
execute_rollback() {
    print_header "Ejecutando Rollback"

    TARGET_IMAGE="$ACR_LOGIN_SERVER/$SERVICE_NAME:$TARGET_VERSION"

    print_info "Cambiando imagen a: $TARGET_IMAGE"

    # Actualizar la imagen del deployment
    kubectl set image deployment/$SERVICE_NAME \
        $SERVICE_NAME=$TARGET_IMAGE \
        -n $NAMESPACE

    print_success "Comando de rollback ejecutado"

    # Esperar el rollout
    print_info "Esperando completación del rollout (timeout: 5 minutos)..."
    if kubectl rollout status deployment/$SERVICE_NAME -n $NAMESPACE --timeout=5m; then
        print_success "Rollout completado exitosamente"
    else
        print_error "Rollout falló o timeout"
        print_info "Para revertir este rollback, use la versión anterior: $CURRENT_VERSION"
        exit 1
    fi
}

# Función para ejecutar health checks
run_health_checks() {
    print_header "Ejecutando Health Checks"

    print_info "Verificando estado de los pods..."
    kubectl get pods -n $NAMESPACE -l app=$SERVICE_NAME

    # Obtener información del servicio
    SERVICE_IP=$(kubectl get svc $SERVICE_NAME -n $NAMESPACE -o jsonpath='{.spec.clusterIP}' 2>/dev/null || echo "")
    SERVICE_PORT=$(kubectl get svc $SERVICE_NAME -n $NAMESPACE -o jsonpath='{.spec.ports[0].port}' 2>/dev/null || echo "8080")

    if [ -z "$SERVICE_IP" ]; then
        print_warning "No se pudo obtener ClusterIP del servicio"
        return
    fi

    print_info "Ejecutando health check en $SERVICE_IP:$SERVICE_PORT..."

    # Intentar health check con context path
    HEALTH_URL_1="http://$SERVICE_IP:$SERVICE_PORT/$SERVICE_NAME/actuator/health"
    # Intentar health check sin context path (para gateway, eureka, etc)
    HEALTH_URL_2="http://$SERVICE_IP:$SERVICE_PORT/actuator/health"

    # Crear pod temporal para health check
    HEALTH_CHECK_POD="health-check-rollback-$$"

    # Intentar primera URL
    HTTP_CODE=$(kubectl run $HEALTH_CHECK_POD \
        --image=curlimages/curl:latest \
        --restart=Never \
        --namespace=$NAMESPACE \
        --rm -i \
        --command -- \
        sh -c "curl -s -o /dev/null -w '%{http_code}' $HEALTH_URL_1" 2>/dev/null || echo "000")

    if [[ "$HTTP_CODE" == 200* ]]; then
        print_success "Health check exitoso (URL con context path)"
    else
        print_warning "Health check falló en URL 1 (HTTP $HTTP_CODE), intentando URL 2..."

        # Intentar segunda URL
        HTTP_CODE=$(kubectl run ${HEALTH_CHECK_POD}-2 \
            --image=curlimages/curl:latest \
            --restart=Never \
            --namespace=$NAMESPACE \
            --rm -i \
            --command -- \
            sh -c "curl -s -o /dev/null -w '%{http_code}' $HEALTH_URL_2" 2>/dev/null || echo "000")

        if [[ "$HTTP_CODE" == 200* ]]; then
            print_success "Health check exitoso (URL raíz)"
        else
            print_error "Health check falló en ambas URLs (HTTP $HTTP_CODE)"
            print_warning "Verifique manualmente el estado del servicio"
        fi
    fi
}

# Función para generar reporte
generate_report() {
    print_header "Reporte de Rollback"

    REPORT_FILE="/tmp/rollback-report-$(date +%Y%m%d-%H%M%S).txt"

    cat > $REPORT_FILE <<EOF
================================================================================
REPORTE DE ROLLBACK
================================================================================

Fecha y Hora: $(date)
Ejecutado por: $(whoami)

INFORMACIÓN DEL SERVICIO
------------------------
Servicio: $SERVICE_NAME
Ambiente: $ENVIRONMENT ($NAMESPACE)
Versión anterior: $CURRENT_VERSION
Versión objetivo: $TARGET_VERSION
Imagen: $ACR_LOGIN_SERVER/$SERVICE_NAME:$TARGET_VERSION

INFRAESTRUCTURA
---------------
AKS Cluster: $AKS_CLUSTER
Resource Group: $AKS_RG
ACR: $ACR_NAME

BACKUP
------
Ubicación: $(cat /tmp/last-rollback-backup.txt 2>/dev/null || echo "No disponible")

STATUS FINAL
------------
Estado del deployment:
$(kubectl get deployment $SERVICE_NAME -n $NAMESPACE 2>/dev/null || echo "Error al obtener deployment")

Pods:
$(kubectl get pods -n $NAMESPACE -l app=$SERVICE_NAME 2>/dev/null || echo "Error al obtener pods")

PRÓXIMOS PASOS
--------------
1. Monitorear métricas en Grafana
2. Revisar logs del servicio
3. Ejecutar smoke tests
4. Validar funcionalidad crítica
5. Documentar incidente en post-mortem

================================================================================
EOF

    print_success "Reporte generado: $REPORT_FILE"
    echo ""
    cat $REPORT_FILE
}

# Función principal
main() {
    print_header "ROLLBACK AUTOMATIZADO - INICIO"

    # Validar parámetros
    validate_params "$@"

    # Confirmación
    echo ""
    print_warning "Va a realizar rollback del servicio $SERVICE_NAME en $ENVIRONMENT"
    print_warning "Versión objetivo: $TARGET_VERSION"
    echo ""
    read -p "¿Está seguro de continuar? (y/n): " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_info "Rollback cancelado"
        exit 0
    fi

    # Ejecutar pasos del rollback
    check_prerequisites
    setup_environment
    get_aks_credentials
    get_current_version
    verify_target_version
    create_backup
    execute_rollback
    run_health_checks
    generate_report

    print_header "ROLLBACK COMPLETADO EXITOSAMENTE"
    print_success "Servicio $SERVICE_NAME revertido a versión $TARGET_VERSION"
    echo ""
    print_warning "RECORDATORIOS:"
    print_warning "1. Monitorear el servicio durante las próximas 24 horas"
    print_warning "2. Ejecutar smoke tests de validación"
    print_warning "3. Revisar métricas y logs"
    print_warning "4. Documentar el incidente"
    print_warning "5. Programar post-mortem si fue necesario"
    echo ""
}

# Ejecutar script
main "$@"
