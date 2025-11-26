# Changelog - Pipeline Template

## [2024-11-25] - Mejora del Health Check Post-Deploy

### Cambios Implementados

#### Health Check Robusto

Se mejoró el paso de verificación post-deploy en el template `microservice-cicd.yml` para incluir un health check robusto que valida que el servicio está realmente funcional, no solo que el pod está corriendo.

**Antes:**
```yaml
- name: Verify deployment
  run: |
    echo "Deployment verification for ${{ inputs.service-name }}"
    kubectl get pods -n ${{ steps.vars.outputs.namespace }} -l app=${{ inputs.service-name }}
    kubectl get svc -n ${{ steps.vars.outputs.namespace }} -l app=${{ inputs.service-name }}
```

**Después:**
```yaml
- name: Verify deployment
  run: |
    echo "Deployment verification for ${{ inputs.service-name }}"
    kubectl get pods -n ${{ steps.vars.outputs.namespace }} -l app=${{ inputs.service-name }}
    kubectl get svc -n ${{ steps.vars.outputs.namespace }} -l app=${{ inputs.service-name }}

- name: Health check
  run: |
    echo "Running health check for ${{ inputs.service-name }}"

    SERVICE_NAME="${{ inputs.service-name }}"
    NAMESPACE="${{ steps.vars.outputs.namespace }}"

    # Get service ClusterIP
    SERVICE_IP=$(kubectl get svc $SERVICE_NAME -n $NAMESPACE -o jsonpath='{.spec.clusterIP}')
    SERVICE_PORT=$(kubectl get svc $SERVICE_NAME -n $NAMESPACE -o jsonpath='{.spec.ports[0].port}')

    echo "Service IP: $SERVICE_IP:$SERVICE_PORT"

    # Run health check from inside cluster using a temporary pod
    kubectl run health-check-pod-${{ github.run_id }} \
      --image=curlimages/curl:latest \
      --restart=Never \
      --namespace=$NAMESPACE \
      --rm -i \
      --command -- \
      sh -c "curl -f -s -o /dev/null -w '%{http_code}' http://$SERVICE_IP:$SERVICE_PORT/actuator/health || exit 1"

    if [ $? -eq 0 ]; then
      echo "✅ Health check passed for ${{ inputs.service-name }}"
    else
      echo "❌ Health check failed for ${{ inputs.service-name }}"
      exit 1
    fi
```

### Beneficios

1. **Validación Real:** Verifica que el endpoint `/actuator/health` responde correctamente
2. **Desde el Cluster:** Ejecuta el health check desde dentro del cluster usando un pod temporal
3. **Fail Fast:** Si el servicio no está saludable, el pipeline falla inmediatamente
4. **Feedback Claro:** Mensajes con emojis para fácil identificación del estado

### Impacto en Microservicios

Este cambio **NO requiere modificaciones** en los workflows individuales de cada microservicio (`ci-dev.yml`, `ci-prod.yml`), ya que solo llaman al template.

El health check se ejecuta automáticamente en:
- Deploys a **dev** (automáticos en push a `develop`)
- Deploys a **prod** (después de aprobación manual en push a `main`)

### Requisitos

Los microservicios deben exponer el endpoint estándar de Spring Boot Actuator:
```
GET /actuator/health
```

Este endpoint ya está configurado en todos los microservicios del proyecto.

---

## Próximos Pasos

Para tests más completos (integration, E2E, performance, security), ver los workflows automatizados en el repositorio `tests/`:
- [tests/WORKFLOWS.md](../tests/WORKFLOWS.md)

---

## Soporte

Para preguntas o issues relacionados con el template:
1. Revisa la documentación en [ARCHITECTURE.md](ARCHITECTURE.md)
2. Consulta ejemplos en [examples/](examples/)
3. Contacta al equipo DevOps
