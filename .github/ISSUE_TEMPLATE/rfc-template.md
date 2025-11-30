---
name: Request for Change (RFC)
about: Solicitud formal de cambio para el sistema de microservicios
title: '[RFC] '
labels: rfc
assignees: ''
---

## Información General

**Tipo de Cambio:** <!-- Standard / Normal / Major / Emergency -->
**Ambiente Objetivo:** <!-- dev / prod / ambos -->
**Servicio(s) Afectado(s):** <!-- user-service, order-service, etc. -->
**Solicitante:** <!-- @username -->
**Fecha de Solicitud:** <!-- YYYY-MM-DD -->
**Fecha de Implementación Propuesta:** <!-- YYYY-MM-DD HH:MM -->

## Descripción del Cambio

### Resumen Ejecutivo
<!-- Descripción breve del cambio en 2-3 líneas -->

### Descripción Detallada
<!-- Explicación completa de qué se va a cambiar y cómo -->

### Justificación
<!-- Por qué es necesario este cambio -->

**Beneficios Esperados:**
- 
- 

**Problemas que Resuelve:**
- 
- 

## Análisis de Impacto

### Impacto Técnico

**Componentes Afectados:**
- [ ] API Gateway
- [ ] Microservicios: <!-- listar cuáles -->
- [ ] Base de datos: <!-- especificar -->
- [ ] Infraestructura: <!-- especificar -->
- [ ] Otros: <!-- especificar -->

**Breaking Changes:**
- [ ] No hay breaking changes
- [ ] Hay breaking changes (describir abajo)

<!-- Si hay breaking changes, describir: -->

### Impacto en Usuarios

**Usuarios Afectados:**
- [ ] Ninguno
- [ ] Internos solamente
- [ ] Usuarios finales

**Tiempo de Inactividad Estimado:**
- [ ] Ninguno
- [ ] < 5 minutos
- [ ] 5-15 minutos
- [ ] > 15 minutos (requiere ventana de mantenimiento)

**Comunicación Requerida:**
- [ ] No requiere comunicación externa
- [ ] Notificación a usuarios internos
- [ ] Anuncio público a usuarios finales

### Dependencias

**Prerequisitos:**
<!-- Listar cambios que deben completarse antes -->
- 

**Cambios Relacionados:**
<!-- Otros PRs o RFCs relacionados -->
- 

**Servicios Dependientes:**
<!-- Servicios que dependen del componente a modificar -->
- 

## Plan de Implementación

### Cambios de Código

**Repositorios Afectados:**
- 

**Ramas:**
- Base: <!-- develop / main -->
- Feature: <!-- feature/nombre -->

**Pull Requests:**
<!-- Links a PRs asociados -->
- 

### Cambios de Configuración

**ConfigMaps:**
- [ ] No requiere cambios
- [ ] Cambios necesarios (describir)

**Secrets:**
- [ ] No requiere cambios
- [ ] Cambios necesarios (describir - sin incluir valores sensibles)

**Variables de Ambiente:**
- [ ] No requiere cambios
- [ ] Cambios necesarios (describir)

### Cambios de Infraestructura

**Terraform:**
- [ ] No requiere cambios
- [ ] Cambios necesarios (describir)

**Manifests K8s:**
- [ ] No requiere cambios
- [ ] Cambios necesarios (describir)

**Recursos Azure:**
- [ ] No requiere cambios
- [ ] Cambios necesarios (describir)

### Pasos de Implementación

1. 
2. 
3. 

**Duración Estimada:** <!-- minutos/horas -->

## Testing

### Tests Unitarios
- [ ] Tests existentes pasan
- [ ] Nuevos tests agregados
- [ ] Cobertura: ____%

### Tests de Integración
- [ ] Tests existentes pasan
- [ ] Nuevos tests agregados

### Tests E2E
- [ ] Tests E2E ejecutados exitosamente
- [ ] Escenarios cubiertos:
  - 
  - 

### Validación Manual
<!-- Pasos para validar manualmente el cambio -->
1. 
2. 
3. 

## Análisis de Calidad y Seguridad

### SonarQube
- [ ] Quality Gate: PASSED
- [ ] Code Smells: <!-- número -->
- [ ] Bugs: <!-- número -->
- [ ] Vulnerabilidades: <!-- número -->
- [ ] Cobertura: ____%

### Trivy Security Scan
- [ ] Sin vulnerabilidades críticas
- [ ] Sin vulnerabilidades altas
- [ ] Vulnerabilidades medias: <!-- número y justificación si aplica -->

### Code Review
- [ ] Revisado por: <!-- @username -->
- [ ] Comentarios resueltos
- [ ] Aprobado

## Plan de Rollback

### Estrategia de Rollback

**Método:**
- [ ] Rollback de Kubernetes (kubectl rollout undo)
- [ ] Rollback vía GitHub Actions workflow
- [ ] Rollback manual con ACR
- [ ] Otro: <!-- especificar -->

**Versión de Rollback:** <!-- versión estable anterior -->

### Procedimiento de Rollback

**Pasos:**
1. 
2. 
3. 

**Tiempo de Rollback Estimado:** <!-- minutos -->

### Criterios para Ejecutar Rollback

Se ejecutará rollback si se presenta alguna de las siguientes condiciones:

- [ ] Tasa de error > 5%
- [ ] Incremento de latencia > 100%
- [ ] Health checks fallan
- [ ] Pérdida de datos detectada
- [ ] Otro: <!-- especificar -->

### Validación Post-Rollback

**Checklist:**
- [ ] Health checks pasan
- [ ] Smoke tests exitosos
- [ ] Métricas normales
- [ ] Validación funcional OK

### Consideraciones Especiales

**Migraciones de BD:**
- [ ] No aplica
- [ ] Script de rollback disponible
- [ ] Backup creado antes del cambio

**Datos:**
- [ ] No hay cambios en datos
- [ ] Cambios son backward compatible
- [ ] Requiere manejo especial: <!-- describir -->

## Riesgos

### Riesgos Identificados

| Riesgo | Probabilidad | Impacto | Mitigación |
|--------|--------------|---------|------------|
| <!-- ej: Fallo de health check --> | <!-- Baja/Media/Alta --> | <!-- Bajo/Medio/Alto --> | <!-- estrategia de mitigación --> |
|  |  |  |  |

### Nivel de Riesgo Global
- [ ] Bajo
- [ ] Medio
- [ ] Alto

## Criterios de Aceptación

El cambio se considerará exitoso cuando:

- [ ] Todos los tests pasan (unitarios, integración, E2E)
- [ ] Quality Gate de SonarQube aprobado
- [ ] Sin vulnerabilidades críticas o altas
- [ ] Health checks exitosos post-deployment
- [ ] Métricas dentro de rangos normales
- [ ] Validación funcional completada
- [ ] <!-- agregar criterios específicos -->

## Aprobaciones Requeridas

<!-- Marcar según tipo de cambio -->

### Cambio Standard
- [ ] Peer Review (1 desarrollador)

### Cambio Normal
- [ ] Tech Lead
- [ ] Product Owner (si afecta funcionalidad)

### Cambio Major
- [ ] Tech Lead
- [ ] Product Owner
- [ ] DevOps Lead
- [ ] Architecture Review Board

### Cambio de Emergencia
- [ ] Aprobación verbal del Tech Lead (documentar)

## Comunicación

### Notificación Pre-Cambio

**Canales:**
- [ ] Slack #deployments
- [ ] Email a stakeholders
- [ ] Anuncio en sistema

**Mensaje:**
<!-- Borrador del mensaje de notificación -->

### Notificación Post-Cambio

**Detalles a Comunicar:**
- Resultado del deployment
- Cambios implementados
- Próximos pasos (si aplica)

## Ventana de Implementación

**Ambiente de Desarrollo:**
- Fecha: <!-- YYYY-MM-DD -->
- Hora: <!-- HH:MM --> (sin restricciones)

**Ambiente de Producción:**
- Fecha: <!-- YYYY-MM-DD -->
- Hora: <!-- HH:MM - HH:MM --> (preferiblemente fuera de horario laboral)
- Ventana de mantenimiento: <!-- si aplica -->

## Monitoreo Post-Implementación

### Métricas a Monitorear (primeras 24h)

- [ ] Tasa de error
- [ ] Latencia (p50, p95, p99)
- [ ] Throughput
- [ ] Uso de recursos (CPU, memoria)
- [ ] Logs de error
- [ ] <!-- otras métricas específicas -->

### Responsable de Monitoreo
- **Primeras 2 horas:** <!-- @username -->
- **Siguientes 24 horas:** <!-- @username -->

## Documentación

### Documentación Actualizada

- [ ] README.md
- [ ] CHANGELOG.md
- [ ] Documentación técnica
- [ ] Runbooks
- [ ] Swagger/OpenAPI (si aplica)

### Release Notes

<!-- Borrador de release notes -->
**Agregado:**
- 

**Cambiado:**
- 

**Corregido:**
- 

**Removido:**
- 

## Checklist Final

### Pre-Implementación
- [ ] RFC aprobado por todos los niveles requeridos
- [ ] Pull Request creado y revisado
- [ ] Tests completos ejecutados y pasando
- [ ] SonarQube Quality Gate aprobado
- [ ] Trivy scan sin vulnerabilidades críticas/altas
- [ ] Plan de rollback documentado y validado
- [ ] Stakeholders notificados
- [ ] Ventana de implementación programada

### Implementación
- [ ] Pipeline CI/CD ejecutado exitosamente
- [ ] Deployment completado sin errores
- [ ] Health checks pasando
- [ ] Smoke tests exitosos

### Post-Implementación
- [ ] Validación funcional completada
- [ ] Métricas normales
- [ ] Documentación actualizada
- [ ] Release notes publicadas
- [ ] Notificación de completación enviada
- [ ] Seguimiento de 24h programado

## Notas Adicionales

<!-- Cualquier información adicional relevante -->

---

**Para aprobar este RFC, los revisores deben:**
1. Revisar todos los puntos de este documento
2. Validar el plan de implementación y rollback
3. Confirmar que los riesgos están adecuadamente mitigados
4. Aprobar mediante comentario en este issue
5. Asignar las labels correspondientes
