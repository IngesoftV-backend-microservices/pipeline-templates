# Arquitectura de CI/CD Pipeline

Este documento describe la arquitectura técnica de los pipelines CI/CD implementados para los microservicios.

## Diagrama de Arquitectura General

```
┌─────────────────────────────────────────────────────────────────────────┐
│                           GitHub Repository                              │
│                                                                           │
│  developer → feature/xxx → PR → develop → [CI-DEV] → AKS Dev            │
│                                    │                                      │
│                                    ↓                                      │
│                              PR (reviewed)                                │
│                                    │                                      │
│                                    ↓                                      │
│                                  main → [CI-PROD] → [APPROVAL] → AKS Prod│
└─────────────────────────────────────────────────────────────────────────┘
```

## Flujo Detallado del Pipeline

### 1. Trigger Events

```yaml
Develop Branch (ci-dev.yml):
  - push to develop
  - workflow_dispatch (manual)

Main Branch (ci-prod.yml):
  - push to main
  - workflow_dispatch (manual)
```

### 2. Pipeline Stages

```
┌─────────────────────────────────────────────────────────────────┐
│ Stage 1: Build & Test                                           │
├─────────────────────────────────────────────────────────────────┤
│ • Checkout code (fetch-depth: 0 for GitVersion)                │
│ • Setup JDK 11 (Temurin) with Maven cache                      │
│ • GitVersion: Calculate semantic version                       │
│ • Generate image tag (v1.2.3-dev or v1.2.3)                    │
│ • Run unit tests with Surefire                                 │
│ • Generate test report (JUnit XML)                             │
│ • Build JAR with Maven                                         │
│ • Upload artifact to GitHub                                    │
│                                                                 │
│ Outputs: version, image-tag                                    │
└─────────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────────┐
│ Stage 2: Code Quality (parallel with Stage 3)                  │
├─────────────────────────────────────────────────────────────────┤
│ • Checkout code                                                 │
│ • Setup JDK 11                                                  │
│ • Cache SonarQube packages                                      │
│ • Run SonarQube Scanner                                         │
│   - Analysis with quality gate                                  │
│   - Code coverage, bugs, vulnerabilities, code smells          │
│   - Wait for quality gate result                               │
│                                                                 │
│ Quality Gate Criteria:                                         │
│ • Coverage > 80%                                                │
│ • No critical bugs                                              │
│ • No blocker vulnerabilities                                    │
└─────────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────────┐
│ Stage 3: Security Scan (parallel with Stage 2)                 │
├─────────────────────────────────────────────────────────────────┤
│ • Checkout code                                                 │
│ • Setup JDK 11                                                  │
│ • Build JAR                                                     │
│ • Trivy scan on target/ folder                                 │
│   - Scan dependencies (JAR)                                     │
│   - Output: SARIF format                                        │
│   - Upload to GitHub Security                                   │
│ • Trivy scan on Dockerfile                                      │
│   - Configuration scan                                          │
│   - Check for misconfigurations                                │
│                                                                 │
│ Severity: CRITICAL, HIGH                                       │
└─────────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────────┐
│ Stage 4: Build & Push Image                                    │
├─────────────────────────────────────────────────────────────────┤
│ • Checkout code                                                 │
│ • Determine ACR (dev/prod)                                      │
│ • Azure login (OIDC/Federated Identity)                        │
│ • ACR login                                                     │
│ • Setup Docker Buildx                                          │
│ • Build multi-platform image                                   │
│   - Build args: SPRING_PROFILES_ACTIVE                         │
│   - Cache layers (registry cache)                              │
│   - Tags: version + latest-env                                 │
│ • Push to ACR                                                   │
│ • Trivy scan on pushed image                                   │
│   - Final security check                                        │
│ • Create Git tag (prod only)                                   │
│                                                                 │
│ Images:                                                         │
│ • acrvingesoftdev.azurecr.io/SERVICE:v1.2.3-dev                │
│ • acrvingesoftprod.azurecr.io/SERVICE:v1.2.3                   │
└─────────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────────┐
│ Stage 5: Deploy to AKS                                         │
├─────────────────────────────────────────────────────────────────┤
│ • Checkout manifests-k8s repository                            │
│ • Set deployment variables (namespace, cluster, RG)            │
│ • Azure login                                                   │
│ • Get AKS credentials                                          │
│ • Update kustomization.yaml                                    │
│   - Set new image tag                                          │
│ • Apply manifests with kubectl                                 │
│   - kubectl apply -k overlays/ENV                              │
│ • Wait for rollout                                             │
│   - Timeout: 5 minutes                                         │
│ • Verify deployment                                            │
│   - Check pods status                                          │
│   - Check service endpoints                                    │
│                                                                 │
│ Environment: dev or prod (with approval gate)                  │
└─────────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────────┐
│ Stage 6: Notify                                                │
├─────────────────────────────────────────────────────────────────┤
│ • Determine overall status                                     │
│ • Send Slack notification                                      │
│   - Service name, environment, version                         │
│   - Status of all stages                                       │
│   - Link to workflow run                                       │
│ • Create GitHub deployment status                              │
│   - Success or failure                                         │
│   - Visible in GitHub deployments                              │
└─────────────────────────────────────────────────────────────────┘
```

## Componentes Técnicos

### GitVersion

**Propósito**: Versionado semántico automático basado en commits

**Configuración**:
```yaml
mode: Mainline
branches:
  develop:
    tag: dev
  main:
    tag: ''
```

**Salidas**:
- `semVer`: 1.2.3
- `fullSemVer`: 1.2.3-dev.5
- `majorMinorPatch`: 1.2.3

### SonarQube

**Propósito**: Análisis estático de código y quality gate

**Métricas analizadas**:
- Code coverage
- Duplications
- Bugs
- Vulnerabilities
- Code smells
- Security hotspots
- Technical debt

**Quality Gate** (default):
```
Coverage > 80%
Duplications < 3%
Maintainability Rating = A
Reliability Rating = A
Security Rating = A
```

### Trivy

**Propósito**: Escaneo de vulnerabilidades en múltiples niveles

**Tipos de escaneo**:
1. **Filesystem** (`target/`): Vulnerabilidades en dependencias Java
2. **Config** (`Dockerfile`): Misconfigurations en Dockerfile
3. **Image**: Vulnerabilidades en imagen final

**Severidades reportadas**: CRITICAL, HIGH

**Salidas**:
- SARIF format → GitHub Code Scanning
- Table format → Workflow logs

### Azure Container Registry (ACR)

**Propósito**: Registry privado de imágenes Docker

**Configuración**:
- **Dev**: `acrvingesoftdev` (SKU: Basic)
- **Prod**: `acrvingesoftprod` (SKU: Standard)

**Autenticación**: Federated Identity (OIDC) - sin passwords

**Cache strategy**: Registry cache en build layers

### Azure Kubernetes Service (AKS)

**Propósito**: Orquestación de containers en Kubernetes

**Configuración**:
```
Dev:
  - Namespace: ecommerce-dev
  - Cluster: aks-ecommerce-dev
  - Nodes: 2x Standard_B2s

Prod:
  - Namespace: ecommerce-prod
  - Cluster: aks-ecommerce-prod
  - Nodes: 3x Standard_D2s_v3
```

**Deployment strategy**: Rolling update con health checks

## Seguridad

### Autenticación Azure (OIDC)

```
┌──────────────┐
│ GitHub       │
│ Actions      │
└──────┬───────┘
       │ Request OIDC token
       ↓
┌──────────────────────────┐
│ GitHub Token Service     │
│ token.actions.github.com │
└──────┬───────────────────┘
       │ JWT token
       ↓
┌──────────────────────────┐
│ Azure AD                 │
│ Federated Identity       │
└──────┬───────────────────┘
       │ Azure access token
       ↓
┌──────────────────────────┐
│ Azure Resources          │
│ (ACR, AKS, etc.)        │
└──────────────────────────┘
```

**Ventajas**:
- ✅ Sin credenciales en secrets
- ✅ Short-lived tokens
- ✅ Scoped to specific repos/branches
- ✅ Auditable en Azure AD

### Secrets Management

**GitHub Secrets** (encrypted):
- `AZURE_CLIENT_ID`
- `AZURE_TENANT_ID`
- `AZURE_SUBSCRIPTION_ID`
- `SONARQUBE_TOKEN`
- `SONARQUBE_HOST_URL`
- `SLACK_WEBHOOK_URL`

**Kubernetes Secrets** (managed by Kustomize):
- Database credentials
- API keys
- TLS certificates

### Permissions

```yaml
permissions:
  contents: write        # Para crear tags
  packages: write        # Para push a registry
  security-events: write # Para upload SARIF
  deployments: write     # Para deployment status
  id-token: write       # Para OIDC authentication
```

## Promoción entre Ambientes

### Environment Protection (Prod)

```yaml
Environment: prod
  Required reviewers: [user1, user2]
  Wait timer: 0 minutes
  Deployment branches: main only
  Environment secrets: (same as org)
```

**Flujo de aprobación**:
1. Pipeline llega a stage "Deploy to AKS"
2. Pausa automática
3. Reviewer recibe notificación
4. Review y approve/reject en GitHub UI
5. Si approve → continúa deployment
6. Si reject → pipeline falla

## Optimizaciones

### Caché

```yaml
Maven cache:
  - ~/.m2/repository
  - Key: ${{ runner.os }}-maven-${{ hashFiles('**/pom.xml') }}

SonarQube cache:
  - ~/.sonar/cache
  - Key: ${{ runner.os }}-sonar

Docker layer cache:
  - Registry cache en ACR
  - Tag: buildcache-{env}
```

### Paralelización

```
build-and-test
      ├─→ code-quality (parallel)
      └─→ security-scan (parallel)
              ↓
      build-and-push-image
              ↓
      deploy-to-aks
              ↓
      notify
```

**Tiempo estimado**:
- Dev: ~8-10 minutos
- Prod: ~10-12 minutos (+ approval time)

## Monitoreo y Observabilidad

### GitHub Actions

- Workflow runs history
- Job logs with timestamps
- Artifact storage (7 days)
- Deployment history

### GitHub Security

- Code scanning alerts (Trivy SARIF)
- Dependency graph
- Security advisories

### Azure Monitor

- AKS cluster metrics
- Container logs
- Application Insights

### SonarQube Dashboard

- Quality trends
- Code coverage evolution
- Technical debt
- Hotspots prioritization

## Rollback Strategy

### Manual Rollback

```bash
# Rollback to previous version in Kubernetes
kubectl rollout undo deployment/user-service -n ecommerce-prod

# Rollback to specific revision
kubectl rollout history deployment/user-service -n ecommerce-prod
kubectl rollout undo deployment/user-service --to-revision=3 -n ecommerce-prod
```

### Automated Rollback (Future)

```yaml
# Health check after deploy
- Check HTTP 200 on /actuator/health
- If fails > 3 times → auto rollback
- Notify team
```

## Métricas DORA

El pipeline permite medir las siguientes métricas:

1. **Deployment Frequency**: Cada push a main
2. **Lead Time for Changes**: Desde commit hasta prod
3. **Time to Restore Service**: Con rollback automático
4. **Change Failure Rate**: Via monitoring + alerts

## Futuras Mejoras

- [ ] Progressive delivery (canary/blue-green)
- [ ] Automated rollback based on metrics
- [ ] Integration tests in pipeline
- [ ] E2E tests with Selenium
- [ ] Performance tests with k6/Locust
- [ ] SBOM generation
- [ ] Signed images (Cosign)
- [ ] Policy enforcement (OPA/Gatekeeper)

---

**Versión**: 1.0
**Última actualización**: 2024-11-22
