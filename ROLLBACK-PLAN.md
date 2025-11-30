# Plan de Rollback - Procedimientos de Reversión

## Introducción

Este documento establece los procedimientos formales para realizar rollback (reversión) de deployments en la plataforma de microservicios de E-Commerce. El rollback es un mecanismo crítico de recuperación que permite restaurar el sistema a un estado estable anterior cuando un deployment presenta problemas.

## Objetivos

- Minimizar el tiempo de inactividad en caso de deployment fallido
- Proporcionar procedimientos claros y probados de rollback
- Garantizar la integridad de datos durante el proceso de reversión
- Documentar lecciones aprendidas para prevenir futuros incidentes

## Tipos de Rollback

### Rollback Automático

El sistema está configurado para realizar rollback automático en los siguientes casos:

**En Ambiente de Desarrollo:**
- Health check falla después del deployment
- Pods no alcanzan estado Ready en 5 minutos
- Errores críticos durante el rollout

**Mecanismo:**
- Kubernetes detecta fallo mediante readiness probes
- RevisionHistoryLimit mantiene las últimas 10 revisiones
- Rollback automático a la revisión anterior

### Rollback Manual

Se requiere intervención manual en los siguientes escenarios:

- Problemas funcionales no detectados por health checks
- Degradación de rendimiento
- Errores reportados por usuarios
- Problemas de integridad de datos
- Decisión de negocio de revertir cambios

## Indicadores para Ejecutar Rollback

### Indicadores Críticos (Rollback Inmediato)

- **Tasa de error mayor al 5%** en endpoints críticos
- **Tiempo de respuesta aumenta más del 100%** comparado con baseline
- **Caída de disponibilidad** de servicios dependientes
- **Pérdida o corrupción de datos** detectada
- **Vulnerabilidad de seguridad** introducida
- **Fallo de health checks** persistente

### Indicadores de Advertencia (Evaluar Rollback)

- Tasa de error entre 1-5%
- Incremento del 50-100% en tiempo de respuesta
- Logs de error inusuales o desconocidos
- Alertas de Prometheus/Grafana
- Feedback negativo de usuarios
- Consumo anormal de recursos

## Procedimientos de Rollback

### Procedimiento 1: Rollback de Kubernetes (Recomendado)

Este es el método más rápido y seguro para revertir deployments.

#### Paso 1: Identificar el Deployment

```bash
# Listar deployments en el namespace
kubectl get deployments -n ecommerce-prod

# Ver historial de revisiones del deployment
kubectl rollout history deployment/<service-name> -n ecommerce-prod
```

#### Paso 2: Verificar Estado Actual

```bash
# Ver estado del rollout actual
kubectl rollout status deployment/<service-name> -n ecommerce-prod

# Ver detalles del deployment
kubectl describe deployment/<service-name> -n ecommerce-prod

# Ver logs del pod problemático
kubectl logs -f deployment/<service-name> -n ecommerce-prod --tail=100
```

#### Paso 3: Ejecutar Rollback

```bash
# Rollback a la revisión anterior
kubectl rollout undo deployment/<service-name> -n ecommerce-prod

# Rollback a una revisión específica
kubectl rollout undo deployment/<service-name> -n ecommerce-prod --to-revision=<revision-number>
```

#### Paso 4: Verificar Rollback

```bash
# Monitorear el rollback
kubectl rollout status deployment/<service-name> -n ecommerce-prod

# Verificar que los pods están corriendo
kubectl get pods -n ecommerce-prod -l app=<service-name>

# Ejecutar health check
kubectl run health-check-temp --image=curlimages/curl:latest --restart=Never \
  --namespace=ecommerce-prod --rm -i --command -- \
  sh -c "curl -f http://<service-name>:8080/actuator/health"
```

#### Paso 5: Validación Post-Rollback

```bash
# Verificar logs del servicio revertido
kubectl logs deployment/<service-name> -n ecommerce-prod --tail=50

# Verificar métricas
kubectl top pods -n ecommerce-prod -l app=<service-name>

# Ejecutar smoke tests
# (Ver sección de Verificación Post-Rollback)
```

### Procedimiento 2: Rollback mediante GitHub Actions

Utilizar el workflow de rollback automatizado para revertir a una versión específica.

#### Paso 1: Identificar Versión Objetivo

```bash
# Listar tags disponibles del servicio
git tag -l "v*" | sort -V | tail -10

# O consultar GitHub Releases
# https://github.com/IngesoftV-backend-microservices/<service-name>/releases
```

#### Paso 2: Ejecutar Workflow de Rollback

1. Ir a GitHub Actions del repositorio del servicio
2. Seleccionar workflow "Rollback to Previous Version"
3. Hacer clic en "Run workflow"
4. Ingresar parámetros:
   - **Service Name:** nombre del servicio (ej: user-service)
   - **Environment:** dev o prod
   - **Target Version:** versión a restaurar (ej: v1.2.0)
5. Confirmar ejecución

#### Paso 3: Monitorear Ejecución

1. Observar progreso del workflow en GitHub Actions
2. Verificar cada job:
   - Validación de versión objetivo
   - Deploy de imagen anterior
   - Health checks
   - Tests de smoke

#### Paso 4: Validación

1. Verificar que el workflow completa exitosamente
2. Confirmar que la versión desplegada es la correcta
3. Ejecutar validación funcional

### Procedimiento 3: Rollback Manual con ACR y Kubectl

Método alternativo cuando los procedimientos anteriores no están disponibles.

#### Paso 1: Identificar Imagen Anterior

```bash
# Login a Azure
az login

# Listar tags de la imagen en ACR
ENV="prod"  # o "dev"
SERVICE_NAME="user-service"
ACR_NAME="acrvingesoftprod"  # o "acrvingesoftdev"

az acr repository show-tags \
  --name $ACR_NAME \
  --repository $SERVICE_NAME \
  --orderby time_desc \
  --output table
```

#### Paso 2: Actualizar Manifest de Kubernetes

```bash
# Opción A: Editar el deployment directamente
kubectl set image deployment/<service-name> \
  <service-name>=<acr-login-server>/<service-name>:<previous-tag> \
  -n ecommerce-prod

# Opción B: Editar manifest y aplicar
cd manifests-k8s/overlays/prod
# Editar kustomization.yaml para cambiar el tag
kubectl apply -k . -n ecommerce-prod
```

#### Paso 3: Verificar Rollout

```bash
# Monitorear el rollout
kubectl rollout status deployment/<service-name> -n ecommerce-prod

# Si hay problemas, pausar el rollout
kubectl rollout pause deployment/<service-name> -n ecommerce-prod

# Si todo está bien, continuar
kubectl rollout resume deployment/<service-name> -n ecommerce-prod
```

## Rollback de Cambios Específicos

### Rollback de Cambios de Configuración

#### ConfigMaps

```bash
# Ver historial de ConfigMaps (requiere backup previo)
kubectl get configmap -n ecommerce-prod

# Aplicar ConfigMap anterior desde backup
kubectl apply -f <backup-configmap>.yaml -n ecommerce-prod

# Reiniciar pods para aplicar configuración
kubectl rollout restart deployment/<service-name> -n ecommerce-prod
```

#### Secrets

```bash
# NOTA: Los Secrets deben respaldarse de forma segura antes de cambios

# Aplicar Secret anterior desde backup cifrado
kubectl apply -f <backup-secret>.yaml -n ecommerce-prod

# Reiniciar pods
kubectl rollout restart deployment/<service-name> -n ecommerce-prod
```

### Rollback de Cambios de Infraestructura (Terraform)

En caso de que cambios de infraestructura causen problemas:

#### Paso 1: Identificar Estado Anterior

```bash
cd infra

# Ver historial de estados en backend
az storage blob list \
  --account-name sttfstatevingesoft \
  --container-name terraform-state \
  --output table

# Listar versiones del archivo de estado
terraform state list
```

#### Paso 2: Revertir con Git

```bash
# Ver commits recientes
git log --oneline -10

# Checkout del commit anterior
git checkout <previous-commit-hash>

# O revertir commit específico
git revert <commit-hash>
```

#### Paso 3: Aplicar Estado Anterior

```bash
# Revisar plan
terraform plan -var-file="environments/prod/terraform.tfvars"

# Aplicar cambios
terraform apply -var-file="environments/prod/terraform.tfvars"
```

### Rollback de Migraciones de Base de Datos

Las migraciones de base de datos requieren atención especial:

#### Consideraciones Importantes

- **No se deben realizar rollbacks destructivos** (pérdida de datos)
- Validar que la versión anterior es compatible con datos nuevos
- Considerar migración forward en lugar de rollback
- Respaldar base de datos antes de cualquier acción

#### Procedimiento

1. **Detener escrituras** al servicio afectado
2. **Crear backup completo** de la base de datos
3. **Ejecutar script de rollback** de la migración (si existe)
4. **Validar integridad** de datos
5. **Revertir servicio** a versión anterior
6. **Ejecutar tests** de validación
7. **Reactivar** el servicio

## Script de Rollback Automatizado

Se proporciona un script para facilitar el proceso de rollback:

### Ubicación

```bash
scripts/rollback-service.sh
```

### Uso

```bash
# Sintaxis
./scripts/rollback-service.sh <service-name> <environment> <target-version>

# Ejemplos
./scripts/rollback-service.sh user-service prod v1.2.0
./scripts/rollback-service.sh order-service dev v0.5.3
```

### Funcionalidades

El script realiza las siguientes operaciones:

1. Validación de parámetros
2. Autenticación con Azure
3. Verificación de que la versión objetivo existe
4. Backup del estado actual
5. Ejecución del rollback
6. Health checks automáticos
7. Generación de reporte

## Verificación Post-Rollback

Después de ejecutar un rollback, es crítico verificar que el sistema funciona correctamente:

### 1. Health Checks

```bash
# Verificar endpoint de salud
curl http://<service-ip>:8080/actuator/health

# Debe retornar: {"status":"UP"}
```

### 2. Smoke Tests

Ejecutar tests básicos de funcionalidad:

```bash
# Acceder al repositorio de tests
cd tests

# Ejecutar smoke tests del servicio
pytest smoke/test_<service-name>.py -v
```

### 3. Validación de Métricas

- Verificar tasa de error en Grafana
- Confirmar tiempo de respuesta normal
- Validar throughput de requests
- Revisar uso de recursos (CPU, memoria)

### 4. Validación Funcional

Ejecutar casos de prueba manuales de funcionalidad crítica según el servicio:

**User Service:**
- Login de usuario
- Registro de usuario
- Obtener perfil

**Order Service:**
- Crear orden
- Consultar orden
- Actualizar estado

**Payment Service:**
- Procesar pago
- Consultar estado de pago

## Comunicación Durante Rollback

### Notificación de Inicio de Rollback

**Canal:** Slack #deployments

**Mensaje:**
```
ROLLBACK EN PROGRESO
Servicio: <service-name>
Ambiente: <environment>
Versión actual: <current-version>
Versión objetivo: <target-version>
Responsable: <person-name>
Motivo: <brief-description>
ETA: <estimated-time>
```

### Notificación de Completación

**Canal:** Slack #deployments

**Mensaje:**
```
ROLLBACK COMPLETADO
Servicio: <service-name>
Ambiente: <environment>
Versión revertida a: <target-version>
Estado: EXITOSO / FALLIDO
Health Check: OK / FAILED
Duración: <duration>
```

### Escalamiento

Si el rollback no resuelve el problema:

1. **Notificar a Tech Lead** inmediatamente
2. **Escalar a equipo de arquitectura** si el problema persiste
3. **Activar protocolo de incident management** para issues críticos
4. **Considerar rollback a versión más antigua** o degradación de servicio

## Post-Mortem Post-Rollback

Después de cada rollback, se debe realizar un análisis post-mortem:

### 1. Documentación del Incidente

Crear un documento que incluya:

- **Cronología:** Timeline detallado del incidente
- **Causa raíz:** Análisis de por qué falló el deployment
- **Impacto:** Usuarios afectados, servicios impactados, duración
- **Acciones tomadas:** Pasos ejecutados durante el rollback
- **Efectividad:** Qué funcionó y qué no

### 2. Lecciones Aprendidas

Identificar:

- Qué se pudo haber prevenido
- Gaps en el proceso de testing
- Mejoras necesarias en el proceso de deployment
- Actualizaciones requeridas en documentación

### 3. Acciones Correctivas

Definir:

- Tasks para prevenir recurrencia
- Mejoras en pipelines de CI/CD
- Tests adicionales requeridos
- Actualizaciones de runbooks

### 4. Compartir Conocimiento

- Presentar hallazgos al equipo
- Actualizar documentación
- Agregar casos de prueba
- Mejorar monitoreo y alertas

## Prevención de Rollbacks

### Estrategias para Reducir Necesidad de Rollbacks

1. **Testing Riguroso:**
   - Aumentar cobertura de tests unitarios (objetivo: 85%+)
   - Implementar tests de integración comprehensivos
   - Ejecutar tests E2E antes de prod
   - Realizar pruebas de carga

2. **Deployment Gradual:**
   - Implementar canary deployments
   - Usar blue-green deployment para servicios críticos
   - Deployment en horarios de bajo tráfico

3. **Feature Flags:**
   - Desplegar código desactivado
   - Activar features gradualmente
   - Rollback sin redeployment

4. **Monitoreo Proactivo:**
   - Alertas tempranas de degradación
   - Dashboards en tiempo real
   - Correlación de eventos

5. **Automated Rollback:**
   - Implementar rollback automático basado en métricas
   - SLO/SLI monitoring
   - Circuit breakers

## Checklist de Rollback

### Pre-Rollback
- [ ] Identificar versión objetivo para rollback
- [ ] Verificar que versión objetivo está disponible
- [ ] Notificar al equipo del inicio de rollback
- [ ] Crear backup del estado actual (si aplica)
- [ ] Identificar responsable del rollback

### Durante Rollback
- [ ] Ejecutar procedimiento de rollback apropiado
- [ ] Monitorear progreso del rollout
- [ ] Verificar que pods alcanzan estado Ready
- [ ] Ejecutar health checks
- [ ] Verificar logs en busca de errores

### Post-Rollback
- [ ] Confirmar que health checks pasan
- [ ] Ejecutar smoke tests
- [ ] Validar métricas clave (error rate, latency)
- [ ] Realizar validación funcional
- [ ] Notificar completación al equipo
- [ ] Documentar incidente y rollback
- [ ] Programar post-mortem

## Matriz de Responsabilidades

| Rol | Decisión de Rollback | Ejecución | Validación | Post-Mortem |
|-----|---------------------|-----------|------------|-------------|
| Developer | Recomienda | Asiste | Ejecuta tests | Participa |
| Tech Lead | Aprueba | Supervisa | Aprueba | Conduce |
| DevOps Engineer | Recomienda | Ejecuta | Valida infraestructura | Participa |
| Product Owner | Informa | N/A | Validación funcional | Participa |

## Tiempos Objetivo (SLA)

### Ambiente de Desarrollo
- **Detección de problema:** Inmediata (monitoreo automático)
- **Decisión de rollback:** < 5 minutos
- **Ejecución de rollback:** < 10 minutos
- **Validación post-rollback:** < 5 minutos
- **Total:** < 20 minutos

### Ambiente de Producción
- **Detección de problema:** < 5 minutos
- **Decisión de rollback:** < 10 minutos
- **Ejecución de rollback:** < 15 minutos
- **Validación post-rollback:** < 10 minutos
- **Total:** < 40 minutos

## Anexos

### Anexo A: Comandos de Referencia Rápida

```bash
# Ver deployments
kubectl get deployments -n ecommerce-prod

# Ver historial de revisiones
kubectl rollout history deployment/<service> -n ecommerce-prod

# Rollback a versión anterior
kubectl rollout undo deployment/<service> -n ecommerce-prod

# Rollback a revisión específica
kubectl rollout undo deployment/<service> -n ecommerce-prod --to-revision=<N>

# Estado del rollout
kubectl rollout status deployment/<service> -n ecommerce-prod

# Ver logs
kubectl logs -f deployment/<service> -n ecommerce-prod

# Health check
kubectl run test --image=curlimages/curl:latest --restart=Never -n ecommerce-prod \
  --rm -i --command -- sh -c "curl -f http://<service>:8080/actuator/health"
```

### Anexo B: Contactos de Escalamiento

| Nivel | Rol | Contacto | Disponibilidad |
|-------|-----|----------|----------------|
| L1 | Developer on-duty | Slack: #dev-on-call | 24/7 |
| L2 | Tech Lead | Slack: @tech-lead | 24/7 |
| L3 | DevOps Lead | Slack: @devops-lead | 24/7 |
| L4 | Architecture Team | Email: arch-team@company.com | Business hours |

### Anexo C: Referencias

- Kubernetes Deployments: https://kubernetes.io/docs/concepts/workloads/controllers/deployment/
- Kubernetes Rollback: https://kubernetes.io/docs/concepts/workloads/controllers/deployment/#rolling-back-a-deployment
- Azure AKS Best Practices: https://learn.microsoft.com/azure/aks/operator-best-practices-cluster-updates
- Site Reliability Engineering: https://sre.google/sre-book/table-of-contents/

## Historial de Cambios

| Versión | Fecha | Autor | Descripción |
|---------|-------|-------|-------------|
| 1.0.0 | 2024-11-29 | DevOps Team | Versión inicial del plan de rollback |
