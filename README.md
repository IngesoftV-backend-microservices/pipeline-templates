# CI/CD Pipeline Templates

Plantillas reutilizables de GitHub Actions para pipelines CI/CD de microservicios.

## ⚠️ Requisitos Previos

Este template requiere **self-hosted runners** configurados en cada máquina de desarrollo.

📖 **Ver [SELF-HOSTED-SETUP.md](../SELF-HOSTED-SETUP.md) para instrucciones completas de configuración.**

## Arquitectura

Este repositorio contiene un **reusable workflow** que implementa un pipeline completo de CI/CD siguiendo las mejores prácticas de DevOps:

```
┌─────────────────────────────────────────────────────────────┐
│                    Reusable Workflow                        │
│                                                             │
│  Build → Test → SonarQube → Trivy → Build Image → Deploy  │
└─────────────────────────────────────────────────────────────┘
                            ▲
                            │ (calls)
        ┌──────────────────┬┴──────────────────┐
        │                  │                   │
    ci-dev.yml        ci-prod.yml        (otros repos)
  (push develop)      (push main)
```

## Características

✅ **Versionado Semántico Automático** con GitVersion
✅ **Análisis Estático de Código** con SonarQube
✅ **Escaneo de Vulnerabilidades** con Trivy (JAR, Dockerfile, Imagen)
✅ **Build Multi-stage** de imágenes Docker optimizadas
✅ **Push a Azure Container Registry** (ACR)
✅ **Despliegue a AKS** con Kustomize
✅ **Promoción Controlada** dev → prod con aprobación manual
✅ **Notificaciones** a Slack en caso de fallos
✅ **Caché de Maven** para builds más rápidos
✅ **Test Reports** con visualización en GitHub
✅ **Security Scanning** integrado con GitHub Security

## Workflows Incluidos

### 1. Reusable Workflow: `microservice-cicd.yml`

Pipeline base que ejecuta:

**Jobs:**
1. `build-and-test`: Build Maven + Tests unitarios + Versionado
2. `code-quality`: Análisis SonarQube + Quality Gate
3. `security-scan`: Trivy en JAR y Dockerfile
4. `build-and-push-image`: Docker build + Push a ACR + Trivy en imagen
5. `deploy-to-aks`: Deploy a Kubernetes con kubectl + kustomize
6. `notify`: Notificaciones Slack + GitHub Deployment Status

**Inputs:**
- `service-name`: Nombre del microservicio (ej: `user-service`)
- `environment`: Ambiente (`dev` o `prod`)
- `java-version`: Versión de Java (default: `11`)
- `maven-version`: Versión de Maven (default: `3.9`)
- `skip-tests`: Saltar tests (default: `false`)

**Secrets Required:**
- `AZURE_CLIENT_ID`
- `AZURE_TENANT_ID`
- `AZURE_SUBSCRIPTION_ID`
- `SONARQUBE_TOKEN`
- `SONARQUBE_HOST_URL`
- `SLACK_WEBHOOK_URL` (opcional)

### 2. Templates para Microservicios

Ubicados en `/examples/`:
- `ci-dev.yml`: Workflow para rama `develop` → deploy a DEV
- `ci-prod.yml`: Workflow para rama `main` → deploy a PROD

## Setup e Instalación

### Paso 1: Configurar GitHub Secrets

Cada repositorio de microservicio necesita los siguientes secrets:

#### Azure Credentials (Federated Identity)

```bash
# 1. Crear Service Principal con Federated Credentials
az ad sp create-for-rbac --name "github-actions-sp" --role contributor \
  --scopes /subscriptions/{SUBSCRIPTION_ID}

# 2. Configurar Federated Credential para cada repo
az ad app federated-credential create \
  --id {APP_ID} \
  --parameters '{
    "name": "github-actions-{service-name}",
    "issuer": "https://token.actions.githubusercontent.com",
    "subject": "repo:IngesoftV-backend-microservices/{service-name}:ref:refs/heads/main",
    "audiences": ["api://AzureADTokenExchange"]
  }'
```

#### Secrets a configurar en GitHub:

```bash
# En cada repositorio: Settings → Secrets and variables → Actions → New repository secret

AZURE_CLIENT_ID          # Application (client) ID del Service Principal
AZURE_TENANT_ID          # Directory (tenant) ID
AZURE_SUBSCRIPTION_ID    # Subscription ID de Azure
SONARQUBE_TOKEN          # Token de autenticación de SonarQube
SONARQUBE_HOST_URL       # URL del servidor SonarQube (ej: https://sonarqube.example.com)
SLACK_WEBHOOK_URL        # (Opcional) Webhook URL de Slack para notificaciones
```

### Paso 2: Configurar GitHub Environments

Cada repositorio debe tener dos environments configurados:

#### Environment: `dev`
```bash
# Settings → Environments → New environment: "dev"
# No protection rules (auto-deploy)
```

#### Environment: `prod`
```bash
# Settings → Environments → New environment: "prod"

# Protection rules:
✅ Required reviewers: 1-2 personas
✅ Wait timer: 0 minutes (opcional: agregar delay)
✅ Deployment branches: Only protected branches (main)
```

### Paso 3: Instalar Workflows en Cada Microservicio

Para cada uno de los 10 microservicios:

```bash
# Navegar al repositorio del microservicio
cd user-service  # (o cualquier otro servicio)

# Crear estructura de workflows
mkdir -p .github/workflows

# Copiar los workflows ya creados (están en cada repo ahora)
# O usar los templates de /examples/ y reemplazar SERVICE_NAME_HERE

# Commit y push
git add .github/workflows/
git commit -m "ci: add CI/CD pipelines"
git push origin develop
```

### Paso 4: Configurar SonarQube

```bash
# 1. Instalar SonarQube (Docker)
docker run -d --name sonarqube \
  -p 9000:9000 \
  -e SONAR_ES_BOOTSTRAP_CHECKS_DISABLE=true \
  sonarqube:latest

# 2. Acceder a http://localhost:9000
# Login: admin / admin (cambiar password)

# 3. Crear proyecto para cada microservicio
# Administration → Projects → Create Project
# - Project key: user-service (mismo nombre que service-name)
# - Project name: user-service

# 4. Generar token
# My Account → Security → Generate Token
# Guardar en GitHub Secret: SONARQUBE_TOKEN
```

## Flujo de Trabajo

### Desarrollo en DEV

```bash
# 1. Crear rama feature
git checkout develop
git pull origin develop
git checkout -b feature/nueva-funcionalidad

# 2. Desarrollar y hacer commits
git add .
git commit -m "feat: agregar nueva funcionalidad"

# 3. Push a feature branch
git push origin feature/nueva-funcionalidad

# 4. Crear PR hacia develop
# En GitHub: New Pull Request → base: develop ← compare: feature/nueva-funcionalidad

# 5. Merge a develop → DISPARA PIPELINE CI-DEV
# ✓ Build & Test
# ✓ SonarQube Analysis
# ✓ Trivy Security Scan
# ✓ Build & Push imagen a acrvingesoftdev.azurecr.io
# ✓ Deploy automático a AKS namespace ecommerce-dev
```

### Promoción a PROD

```bash
# 1. Crear PR de develop → main
# En GitHub: New Pull Request → base: main ← compare: develop

# 2. Code Review + Aprobación

# 3. Merge a main → DISPARA PIPELINE CI-PROD
# ✓ Build & Test
# ✓ SonarQube Analysis
# ✓ Trivy Security Scan
# ✓ Build & Push imagen a acrvingesoftprod.azurecr.io
# ⏸️  ESPERA APROBACIÓN MANUAL (GitHub Environment Protection)

# 4. Aprobar despliegue en GitHub
# Actions → Workflow en ejecución → Review deployments → Approve

# 5. Despliegue a producción
# ✓ Deploy a AKS namespace ecommerce-prod
# ✓ Crear Git tag (v1.2.3)
# ✓ GitHub Release (opcional)
```

## Versionado Semántico

El pipeline usa **GitVersion** con modo **Mainline** para generar versiones automáticamente:

### Reglas de versionado:

```
develop → v1.2.3-dev (pre-release)
main    → v1.2.3 (release)
```

### Control de versión mediante commits:

```bash
# PATCH: v1.2.3 → v1.2.4
git commit -m "fix: corregir bug en validación"

# MINOR: v1.2.3 → v1.3.0
git commit -m "feat: agregar nuevo endpoint"

# MAJOR: v1.2.3 → v2.0.0
git commit -m "feat!: cambio breaking en API"
# o
git commit -m "feat: nueva arquitectura

BREAKING CHANGE: La API v1 ya no es compatible"
```

## Notificaciones

### Slack Integration

```bash
# 1. Crear Incoming Webhook en Slack
# Workspace → Apps → Incoming Webhooks → Add to Slack
# Seleccionar canal (ej: #deployments)

# 2. Copiar Webhook URL
# https://hooks.slack.com/services/T00000000/B00000000/XXXXXXXXXXXXXXXXXXXX

# 3. Guardar en GitHub Secret
# SLACK_WEBHOOK_URL = <webhook-url>

# 4. El pipeline enviará notificaciones automáticamente:
# ✅ Pipeline success for user-service
# ❌ Pipeline failure for user-service
```

### Formato de notificación:

```
✅ Pipeline success

Service: user-service
Environment: prod
Version: v1.2.3
Triggered by: @username

Status:
• Build & Test: success
• Code Quality: success
• Security Scan: success
• Build Image: success
• Deploy: success

[View Workflow]
```

## Resolución de Problemas

### Pipeline falla en SonarQube

```bash
# Verificar que el token es válido
curl -u ${SONARQUBE_TOKEN}: ${SONARQUBE_HOST_URL}/api/authentication/validate

# Verificar que el proyecto existe
curl -u ${SONARQUBE_TOKEN}: ${SONARQUBE_HOST_URL}/api/projects/search?projects=user-service

# Desactivar Quality Gate temporalmente (no recomendado)
# En el workflow, remover: -Dsonar.qualitygate.wait=true
```

### Pipeline falla en Trivy

```bash
# Si hay vulnerabilidades críticas, revisar el reporte
# GitHub → Security → Code scanning alerts

# Actualizar dependencias en pom.xml
mvn versions:display-dependency-updates

# Re-build la imagen con dependencias actualizadas
```

### Pipeline falla en Deploy

```bash
# Verificar credenciales de AKS
az aks get-credentials \
  --resource-group rg-ecommerce-microservices-dev \
  --name aks-ecommerce-dev

# Verificar que el namespace existe
kubectl get namespace ecommerce-dev

# Verificar manifiestos
kubectl kustomize manifests/overlays/dev
```

## Estructura de Archivos

```
pipeline-templates/
├── .github/workflows/
│   └── microservice-cicd.yml          # Reusable workflow
├── examples/
│   ├── ci-dev.yml                     # Template para desarrollo
│   └── ci-prod.yml                    # Template para producción
├── README.md                          # Esta documentación
└── SETUP.md                           # Guía de configuración

user-service/                          # (Ejemplo de microservicio)
└── .github/workflows/
    ├── ci-dev.yml                     # Pipeline development
    └── ci-prod.yml                    # Pipeline production
```

## Mejores Prácticas

✅ **Siempre trabajar en feature branches**
✅ **PR obligatorios** para merge a develop y main
✅ **Code reviews** antes de merge
✅ **Tests unitarios** con >80% cobertura
✅ **Quality Gate** de SonarQube debe pasar
✅ **Sin vulnerabilidades críticas** en Trivy
✅ **Aprobación manual** para deploy a producción
✅ **Rollback plan** documentado
✅ **Monitoreo post-deploy** en Grafana/Prometheus

## Próximos Pasos

- [ ] Integrar pruebas de integración
- [ ] Agregar pruebas E2E con Selenium
- [ ] Implementar smoke tests post-deploy
- [ ] Configurar auto-rollback en caso de fallo
- [ ] Agregar métricas DORA (deployment frequency, lead time, etc.)
- [ ] Implementar Progressive Delivery (canary, blue-green)

## Soporte

Para issues o preguntas:
- GitHub Issues: [pipeline-templates/issues](https://github.com/IngesoftV-backend-microservices/pipeline-templates/issues)
- Slack: #devops-support

---

**Autores**: DevOps Team - IngesoftV
**Licencia**: MIT
