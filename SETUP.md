# Guía de Configuración Paso a Paso

Esta guía te llevará a través de todos los pasos necesarios para configurar los pipelines CI/CD.

## Prerequisitos

- Acceso de administrador a GitHub Organization `IngesoftV-backend-microservices`
- Acceso de Owner/Contributor a Azure Subscription
- Azure CLI instalado localmente
- SonarQube server disponible (o instalación nueva)

## Parte 1: Configuración de Azure

### 1.1 Crear Service Principal con Federated Identity

```bash
# Login a Azure
az login

# Verificar suscripción activa
SUBSCRIPTION_ID=$(az account show --query id -o tsv)
echo "Subscription ID: $SUBSCRIPTION_ID"

# Crear Service Principal
SP_OUTPUT=$(az ad sp create-for-rbac \
  --name "github-actions-microservices" \
  --role contributor \
  --scopes /subscriptions/$SUBSCRIPTION_ID \
  --sdk-auth)

# Guardar estos valores (IMPORTANTE)
CLIENT_ID=$(echo $SP_OUTPUT | jq -r '.clientId')
TENANT_ID=$(echo $SP_OUTPUT | jq -r '.tenantId')

echo "AZURE_CLIENT_ID: $CLIENT_ID"
echo "AZURE_TENANT_ID: $TENANT_ID"
echo "AZURE_SUBSCRIPTION_ID: $SUBSCRIPTION_ID"
```

### 1.2 Configurar Federated Credentials para cada repositorio

Para **cada microservicio**, ejecutar:

```bash
# Obtener APP_ID del Service Principal
APP_ID=$(az ad sp show --id $CLIENT_ID --query appId -o tsv)

# Lista de servicios
SERVICES=(
  "user-service"
  "api-gateway"
  "order-service"
  "payment-service"
  "product-service"
  "shipping-service"
  "favourite-service"
  "proxy-client"
  "cloud-config"
  "service-discovery"
)

# Para cada servicio, crear federated credential
for SERVICE in "${SERVICES[@]}"; do
  echo "Configurando $SERVICE..."

  # Para rama develop (dev environment)
  az ad app federated-credential create \
    --id $APP_ID \
    --parameters "{
      \"name\": \"github-${SERVICE}-dev\",
      \"issuer\": \"https://token.actions.githubusercontent.com\",
      \"subject\": \"repo:IngesoftV-backend-microservices/${SERVICE}:ref:refs/heads/develop\",
      \"audiences\": [\"api://AzureADTokenExchange\"],
      \"description\": \"GitHub Actions for ${SERVICE} development\"
    }"

  # Para rama main (prod environment)
  az ad app federated-credential create \
    --id $APP_ID \
    --parameters "{
      \"name\": \"github-${SERVICE}-prod\",
      \"issuer\": \"https://token.actions.githubusercontent.com\",
      \"subject\": \"repo:IngesoftV-backend-microservices/${SERVICE}:ref:refs/heads/main\",
      \"audiences\": [\"api://AzureADTokenExchange\"],
      \"description\": \"GitHub Actions for ${SERVICE} production\"
    }"

  echo "✓ $SERVICE configurado"
done

echo ""
echo "Federated credentials creados exitosamente!"
```

### 1.3 Verificar permisos

```bash
# Verificar que el Service Principal tiene acceso a los ACRs
az role assignment list --assignee $CLIENT_ID --output table

# Debería mostrar:
# - Contributor en la subscription
# - AcrPull en los ACRs (si ya están creados)
```

## Parte 2: Configuración de SonarQube

### 2.1 Instalar SonarQube (Docker)

```bash
# Crear volúmenes para persistencia
docker volume create sonarqube_data
docker volume create sonarqube_logs
docker volume create sonarqube_extensions

# Ejecutar SonarQube
docker run -d --name sonarqube \
  -p 9000:9000 \
  -e SONAR_ES_BOOTSTRAP_CHECKS_DISABLE=true \
  -v sonarqube_data:/opt/sonarqube/data \
  -v sonarqube_logs:/opt/sonarqube/logs \
  -v sonarqube_extensions:/opt/sonarqube/extensions \
  sonarqube:latest

# Esperar a que inicie (~1 minuto)
echo "Esperando a que SonarQube inicie..."
until curl -s http://localhost:9000/api/system/status | grep -q "UP"; do
  sleep 5
  echo "Esperando..."
done

echo "SonarQube está listo en http://localhost:9000"
echo "Login inicial: admin / admin"
```

### 2.2 Configurar SonarQube

```bash
# 1. Acceder a http://localhost:9000
# 2. Login: admin / admin
# 3. Cambiar contraseña cuando se solicite

# 4. Crear proyectos para cada microservicio
# Administration → Projects → Management → Create Project

# O via API:
SONAR_TOKEN="admin"  # Usar token después de crearlo en paso 2.3

for SERVICE in "${SERVICES[@]}"; do
  curl -X POST "http://localhost:9000/api/projects/create" \
    -u $SONAR_TOKEN: \
    -d "name=$SERVICE" \
    -d "project=$SERVICE"

  echo "Proyecto $SERVICE creado en SonarQube"
done
```

### 2.3 Generar Token de Autenticación

```bash
# Via UI:
# 1. My Account → Security → Generate Tokens
# 2. Name: "github-actions"
# 3. Type: "User Token"
# 4. Expires: No expiration
# 5. Generate → Copiar token

# Via API:
SONAR_USER_TOKEN=$(curl -X POST "http://localhost:9000/api/user_tokens/generate" \
  -u admin:admin \
  -d "name=github-actions" | jq -r '.token')

echo "SONARQUBE_TOKEN: $SONAR_USER_TOKEN"
```

## Parte 3: Configuración de GitHub

### 3.1 Configurar Secrets a Nivel de Organización (Recomendado)

```bash
# Via GitHub CLI (gh)
gh auth login

# Configurar secrets para toda la organización
gh secret set AZURE_CLIENT_ID -b"$CLIENT_ID" --org IngesoftV-backend-microservices
gh secret set AZURE_TENANT_ID -b"$TENANT_ID" --org IngesoftV-backend-microservices
gh secret set AZURE_SUBSCRIPTION_ID -b"$SUBSCRIPTION_ID" --org IngesoftV-backend-microservices
gh secret set SONARQUBE_TOKEN -b"$SONAR_USER_TOKEN" --org IngesoftV-backend-microservices
gh secret set SONARQUBE_HOST_URL -b"http://YOUR_SONARQUBE_IP:9000" --org IngesoftV-backend-microservices

# Opcional: Slack webhook
gh secret set SLACK_WEBHOOK_URL -b"https://hooks.slack.com/services/YOUR/WEBHOOK/URL" --org IngesoftV-backend-microservices
```

### 3.2 Configurar Secrets por Repositorio (Alternativa)

Si no tienes acceso a organización, configurar en cada repo:

```bash
for SERVICE in "${SERVICES[@]}"; do
  echo "Configurando secrets para $SERVICE..."

  gh secret set AZURE_CLIENT_ID -b"$CLIENT_ID" --repo IngesoftV-backend-microservices/$SERVICE
  gh secret set AZURE_TENANT_ID -b"$TENANT_ID" --repo IngesoftV-backend-microservices/$SERVICE
  gh secret set AZURE_SUBSCRIPTION_ID -b"$SUBSCRIPTION_ID" --repo IngesoftV-backend-microservices/$SERVICE
  gh secret set SONARQUBE_TOKEN -b"$SONAR_USER_TOKEN" --repo IngesoftV-backend-microservices/$SERVICE
  gh secret set SONARQUBE_HOST_URL -b"http://YOUR_SONARQUBE_IP:9000" --repo IngesoftV-backend-microservices/$SERVICE

  echo "✓ Secrets configurados para $SERVICE"
done
```

### 3.3 Crear Environments en cada repositorio

Para **cada microservicio**:

```bash
# Via GitHub UI (recomendado para protection rules):
# 1. Repository → Settings → Environments
# 2. New environment: "dev"
#    - No protection rules
# 3. New environment: "prod"
#    - ✅ Required reviewers (agregar 1-2 personas)
#    - ✅ Deployment branches: Only protected branches

# O via API:
for SERVICE in "${SERVICES[@]}"; do
  # Crear environment dev
  gh api repos/IngesoftV-backend-microservices/$SERVICE/environments/dev --method PUT

  # Crear environment prod con protección
  gh api repos/IngesoftV-backend-microservices/$SERVICE/environments/prod --method PUT \
    -f wait_timer=0 \
    -f prevent_self_review=true \
    -F reviewers[][id]=REVIEWER_ID \
    -F reviewers[][type]=User

  echo "✓ Environments creados para $SERVICE"
done
```

## Parte 4: Configuración de Slack (Opcional)

### 4.1 Crear Incoming Webhook

```bash
# 1. Ir a https://api.slack.com/apps
# 2. Create New App → From scratch
# 3. App Name: "GitHub Actions CI/CD"
# 4. Workspace: Seleccionar tu workspace
# 5. Incoming Webhooks → Activate
# 6. Add New Webhook to Workspace
# 7. Seleccionar canal (ej: #deployments)
# 8. Copiar Webhook URL

SLACK_WEBHOOK="https://hooks.slack.com/services/T00000000/B00000000/XXXXXXXXXXXXXXXXXXXX"

# Configurar en GitHub
gh secret set SLACK_WEBHOOK_URL -b"$SLACK_WEBHOOK" --org IngesoftV-backend-microservices
```

### 4.2 Probar Webhook

```bash
curl -X POST $SLACK_WEBHOOK \
  -H 'Content-Type: application/json' \
  -d '{
    "text": "✅ Configuración de pipelines CI/CD completada!"
  }'
```

## Parte 5: Push de Workflows a Repositorios

### 5.1 Push del Reusable Workflow

```bash
cd pipeline-templates

# Verificar archivos
ls -la .github/workflows/microservice-cicd.yml

# Commit y push
git add .
git commit -m "feat: add reusable CI/CD workflow with SonarQube and Trivy"
git push origin main
```

### 5.2 Push de Workflows a cada Microservicio

```bash
# Para cada microservicio
for SERVICE in "${SERVICES[@]}"; do
  echo "Pushing workflows for $SERVICE..."

  cd ../$SERVICE

  # Verificar que los workflows existen
  if [ -d ".github/workflows" ]; then
    git add .github/workflows/
    git commit -m "ci: add CI/CD pipelines for $SERVICE"

    # Push a develop
    git checkout develop
    git push origin develop

    # Push a main (si existe)
    git checkout main 2>/dev/null && git push origin main || echo "No main branch yet"

    echo "✓ Workflows pushed for $SERVICE"
  else
    echo "⚠️  No workflows found for $SERVICE"
  fi
done
```

## Parte 6: Verificación

### 6.1 Verificar Secrets

```bash
# Listar secrets de un repo
gh secret list --repo IngesoftV-backend-microservices/user-service

# Debería mostrar:
# AZURE_CLIENT_ID
# AZURE_TENANT_ID
# AZURE_SUBSCRIPTION_ID
# SONARQUBE_TOKEN
# SONARQUBE_HOST_URL
# SLACK_WEBHOOK_URL
```

### 6.2 Verificar Environments

```bash
gh api repos/IngesoftV-backend-microservices/user-service/environments | jq '.environments[].name'

# Debería mostrar:
# "dev"
# "prod"
```

### 6.3 Test Manual de Pipeline

```bash
cd user-service

# Hacer un cambio trivial
echo "# Test pipeline" >> README.md

git add README.md
git commit -m "test: trigger CI pipeline"
git push origin develop

# Verificar en GitHub Actions
gh run list --repo IngesoftV-backend-microservices/user-service

# Ver logs en tiempo real
gh run watch
```

## Troubleshooting

### Error: "Resource 'IngesoftV-backend-microservices/pipeline-templates/.github/workflows/microservice-cicd.yml@main' not accessible"

**Solución**: El reusable workflow debe estar en un repo público O configurar el repo como "Internal" en GitHub Organization.

```bash
# Opción 1: Hacer público el repo pipeline-templates
gh repo edit IngesoftV-backend-microservices/pipeline-templates --visibility public

# Opción 2: Si es organización Enterprise, configurar como Internal
gh repo edit IngesoftV-backend-microservices/pipeline-templates --visibility internal
```

### Error: "Login failed with Error: Using Auth Type: SERVICE_PRINCIPAL_OIDC"

**Solución**: Federated credential no está configurado correctamente.

```bash
# Verificar que el credential existe
az ad app federated-credential list --id $APP_ID

# Verificar que el subject match
# Debe ser: repo:IngesoftV-backend-microservices/{SERVICE}:ref:refs/heads/{BRANCH}
```

### Error: SonarQube "Quality Gate failed"

**Solución**: Revisar el análisis en SonarQube y corregir issues.

```bash
# Acceder a SonarQube UI
open http://localhost:9000

# Temporalmente desactivar Quality Gate (NO RECOMENDADO)
# En el workflow, comentar: -Dsonar.qualitygate.wait=true
```

## Checklist de Configuración

- [ ] Service Principal creado en Azure
- [ ] Federated credentials configurados (20 credentials: 10 servicios × 2 ambientes)
- [ ] Permisos verificados en Azure
- [ ] SonarQube instalado y corriendo
- [ ] Proyectos creados en SonarQube (10 proyectos)
- [ ] Token de SonarQube generado
- [ ] GitHub Secrets configurados (6 secrets × 10 repos = 60 secrets)
- [ ] GitHub Environments creados (2 environments × 10 repos = 20 environments)
- [ ] Protection rules configuradas en env "prod"
- [ ] Slack webhook configurado (opcional)
- [ ] Reusable workflow pushed a pipeline-templates
- [ ] Workflows individuales pushed a cada microservicio
- [ ] Test manual exitoso en al menos 1 servicio

## Próximos Pasos

Una vez completada la configuración:

1. Crear rama `develop` en todos los repos si no existe
2. Configurar branch protection rules en `main` (require PR, require reviews)
3. Crear primer PR de test para verificar pipeline completo
4. Documentar proceso de deployment para el equipo
5. Configurar Grafana/Prometheus para observabilidad post-deploy

---

**Tiempo estimado de configuración**: 2-3 horas
**Configuración one-time**: Sí (solo se hace una vez)
