# Proceso de Change Management

## Introducción

Este documento establece el proceso formal de gestión de cambios (Change Management) para la plataforma de microservicios de E-Commerce. El proceso define los procedimientos, responsabilidades y criterios de aprobación para realizar cambios en el sistema, garantizando la estabilidad, trazabilidad y cumplimiento de los estándares de calidad.

## Objetivos

El proceso de Change Management tiene los siguientes objetivos:

- Minimizar el riesgo de interrupciones en los servicios de producción
- Asegurar que todos los cambios sean revisados y aprobados adecuadamente
- Mantener un registro completo y auditable de todos los cambios
- Facilitar la coordinación entre equipos de desarrollo y operaciones
- Proporcionar mecanismos de rollback en caso de fallos

## Tipos de Cambios

### Cambio Estándar (Standard Change)

Cambios de bajo riesgo que siguen procedimientos preestablecidos y aprobados previamente.

**Características:**
- Cambios recurrentes y bien documentados
- Procedimiento claro y probado
- Bajo impacto en usuarios
- Puede ser automatizado

**Ejemplos:**
- Actualización de dependencias menores (PATCH)
- Corrección de errores menores
- Cambios de configuración predefinidos
- Ajustes de recursos (CPU, memoria)

**Aprobación:**
- Revisión por pares (peer review)
- CI/CD automático en desarrollo
- Deploy automático a desarrollo

### Cambio Normal (Normal Change)

Cambios que requieren evaluación y aprobación formal antes de su implementación.

**Características:**
- Requiere análisis de impacto
- Necesita aprobación explícita
- Potencial impacto en funcionalidad
- Debe pasar por ambiente de QA

**Ejemplos:**
- Nuevas funcionalidades (MINOR)
- Cambios en APIs existentes
- Modificaciones en lógica de negocio
- Actualización de dependencias mayores

**Aprobación:**
- Revisión por Tech Lead
- Aprobación de Product Owner
- Pruebas en ambiente de desarrollo
- Aprobación manual para producción

### Cambio Mayor (Major Change)

Cambios significativos con alto impacto en el sistema o los usuarios.

**Características:**
- Alto impacto en funcionalidad o arquitectura
- Breaking changes en APIs
- Migración de datos
- Cambios en infraestructura crítica

**Ejemplos:**
- Cambios incompatibles hacia atrás (MAJOR)
- Rediseño de arquitectura
- Migración de bases de datos
- Actualización de versiones de Kubernetes o runtime

**Aprobación:**
- Revisión por comité técnico
- Aprobación de stakeholders clave
- Plan de rollback obligatorio
- Ventana de mantenimiento programada
- Comunicación a todos los stakeholders

### Cambio de Emergencia (Emergency Change)

Cambios urgentes requeridos para resolver incidentes críticos en producción.

**Características:**
- Respuesta a incidentes de producción
- Proceso de aprobación acelerado
- Documentación post-implementación
- Revisión retrospectiva obligatoria

**Ejemplos:**
- Hotfix para vulnerabilidad crítica
- Corrección de bug que impide operación
- Parches de seguridad urgentes
- Rollback de deployment fallido

**Aprobación:**
- Aprobación verbal del Tech Lead
- Notificación inmediata al equipo
- Documentación completa posterior
- Post-mortem obligatorio

## Flujo del Proceso de Cambios

### Fase 1: Solicitud de Cambio (Request for Change - RFC)

1. El solicitante crea un RFC utilizando la plantilla correspondiente
2. El RFC debe incluir:
   - Descripción del cambio
   - Justificación y beneficios esperados
   - Análisis de impacto
   - Plan de implementación
   - Plan de rollback
   - Criterios de aceptación
   - Riesgos identificados

3. El RFC se registra como GitHub Issue con etiqueta `rfc`

### Fase 2: Evaluación y Aprobación

1. **Revisión Técnica:**
   - Tech Lead revisa viabilidad técnica
   - Equipo evalúa impacto en otros componentes
   - Se identifican dependencias y prerequisitos

2. **Evaluación de Riesgos:**
   - Se clasifica el nivel de riesgo (Bajo, Medio, Alto)
   - Se valida el plan de rollback
   - Se determina la ventana de implementación

3. **Aprobación:**
   - Según el tipo de cambio, se requieren las aprobaciones correspondientes
   - Las aprobaciones se registran en el RFC
   - Se programa la implementación

### Fase 3: Implementación

1. **Desarrollo:**
   - Crear rama feature desde develop
   - Implementar cambios siguiendo estándares de código
   - Commits siguiendo Conventional Commits
   - Actualizar documentación relevante

2. **Testing:**
   - Ejecutar tests unitarios
   - Ejecutar tests de integración
   - Validar calidad de código con SonarQube
   - Escaneo de seguridad con Trivy

3. **Revisión de Código:**
   - Pull Request con descripción detallada
   - Code review por al menos un par
   - Validación de CI/CD pipeline

4. **Despliegue a Desarrollo:**
   - Merge a rama develop
   - Deploy automático a ambiente dev
   - Verificación funcional

### Fase 4: Promoción a Producción

1. **Preparación:**
   - Validación completa en desarrollo
   - Documentación de release notes
   - Comunicación a stakeholders
   - Verificación de plan de rollback

2. **Cambio a Producción:**
   - Pull Request de develop a main
   - Revisión final y aprobación
   - Merge a rama main
   - Pipeline CI/CD ejecuta:
     - Build y tests
     - Análisis de calidad y seguridad
     - Build de imagen Docker
     - Espera aprobación manual (deploy gate)
   
3. **Deployment:**
   - Aprobación manual en GitHub Actions
   - Deploy a ambiente de producción
   - Creación automática de Git tag
   - Generación automática de GitHub Release
   - Generación de Release Notes

4. **Verificación Post-Deployment:**
   - Ejecución de smoke tests
   - Verificación de health checks
   - Monitoreo de métricas clave
   - Validación funcional

### Fase 5: Revisión Post-Implementación

1. **Verificación Inmediata (primeras 24 horas):**
   - Monitoreo de logs y métricas
   - Verificación de alertas
   - Confirmación de funcionamiento correcto

2. **Revisión Post-Mortem (si hubo incidentes):**
   - Análisis de causa raíz
   - Identificación de mejoras
   - Actualización de documentación
   - Lecciones aprendidas

## Versionado Semántico

El proyecto utiliza Semantic Versioning (SemVer) de forma automática mediante GitVersion.

### Formato de Versiones

```
MAJOR.MINOR.PATCH[-PRERELEASE]

Ejemplos:
- Desarrollo: v1.2.3-dev
- Producción: v1.2.3
```

### Incremento de Versiones

**PATCH (1.0.0 → 1.0.1):**
- Correcciones de bugs
- Cambios internos sin impacto en API
- Actualizaciones de documentación

**Commits:**
```
fix: corregir validación de email
docs: actualizar README con nuevas instrucciones
```

**MINOR (1.0.0 → 1.1.0):**
- Nuevas funcionalidades compatibles hacia atrás
- Nuevos endpoints o métodos
- Mejoras de rendimiento significativas

**Commits:**
```
feat: agregar endpoint de búsqueda de productos
feat: implementar caché de consultas frecuentes
```

**MAJOR (1.0.0 → 2.0.0):**
- Cambios incompatibles hacia atrás (breaking changes)
- Reestructuración significativa
- Eliminación de funcionalidades deprecadas

**Commits:**
```
feat!: cambiar estructura de respuesta de API

BREAKING CHANGE: El campo 'items' ahora se llama 'products'
```

### Conventional Commits

Todos los commits deben seguir el formato Conventional Commits:

```
<type>[optional scope]: <description>

[optional body]

[optional footer(s)]
```

**Tipos permitidos:**
- `feat`: Nueva funcionalidad
- `fix`: Corrección de bug
- `docs`: Cambios en documentación
- `style`: Cambios de formato (sin cambio de código)
- `refactor`: Refactorización de código
- `perf`: Mejoras de rendimiento
- `test`: Agregar o modificar tests
- `chore`: Cambios en build o herramientas
- `ci`: Cambios en configuración de CI/CD

## Ventanas de Mantenimiento

### Desarrollo (dev)
- **Horario:** 24/7 (sin restricciones)
- **Aprobación:** Automática
- **Rollback:** Automático si falla health check

### Producción (prod)
- **Horario Preferido:** Lunes a Jueves, 22:00 - 02:00 (fuera de horario laboral)
- **Horario Prohibido:** Viernes 18:00 - Lunes 08:00 (excepto emergencias)
- **Aprobación:** Manual obligatoria
- **Notificación:** Mínimo 24 horas de anticipación

### Excepciones

Los cambios de emergencia pueden implementarse en cualquier momento con:
- Aprobación del Tech Lead
- Notificación inmediata al equipo
- Documentación post-implementación

## Checklist de Pre-Deployment

Antes de aprobar un deployment a producción, verificar:

### Código y Calidad
- [ ] Pull Request aprobado por al menos un revisor
- [ ] Todos los tests unitarios pasan
- [ ] Tests de integración exitosos
- [ ] Cobertura de código mayor al 80%
- [ ] SonarQube Quality Gate aprobado
- [ ] Sin vulnerabilidades críticas o altas en Trivy

### Documentación
- [ ] Release notes generadas
- [ ] Documentación técnica actualizada
- [ ] CHANGELOG.md actualizado
- [ ] Plan de rollback documentado

### Infraestructura
- [ ] Cambios en manifiestos K8s revisados
- [ ] ConfigMaps y Secrets verificados
- [ ] Resource limits apropiados
- [ ] Health checks configurados

### Comunicación
- [ ] Stakeholders notificados
- [ ] Equipo de soporte informado
- [ ] Ventana de mantenimiento programada
- [ ] Plan de comunicación en caso de fallo

### Rollback
- [ ] Plan de rollback documentado y probado
- [ ] Versión anterior identificada y disponible
- [ ] Procedimiento de rollback validado
- [ ] Responsables de rollback designados

## Responsabilidades

### Desarrollador
- Crear RFC para cambios normales o mayores
- Implementar cambios siguiendo estándares
- Escribir tests adecuados
- Documentar cambios en código
- Participar en code reviews

### Tech Lead
- Revisar y aprobar RFCs
- Aprobar o rechazar Pull Requests
- Aprobar deployments a producción
- Autorizar cambios de emergencia
- Conducir post-mortems

### DevOps Engineer
- Mantener pipelines CI/CD
- Monitorear deployments
- Ejecutar rollbacks cuando sea necesario
- Gestionar infraestructura
- Optimizar procesos de deployment

### Product Owner
- Priorizar cambios
- Aprobar cambios mayores
- Definir criterios de aceptación
- Comunicar cambios a stakeholders

## Métricas y Reportes

El proceso de Change Management debe medir:

### Métricas de Eficiencia
- **Lead Time:** Tiempo desde RFC hasta producción
- **Deployment Frequency:** Frecuencia de deployments exitosos
- **Change Success Rate:** Porcentaje de cambios exitosos
- **Mean Time to Recovery (MTTR):** Tiempo promedio de recuperación

### Métricas de Calidad
- **Change Failure Rate:** Porcentaje de cambios que requieren rollback
- **Number of Rollbacks:** Cantidad de rollbacks por mes
- **Quality Gate Pass Rate:** Porcentaje de builds que pasan SonarQube
- **Security Vulnerabilities:** Cantidad de vulnerabilidades por severidad

### Reportes Requeridos
- Reporte mensual de cambios implementados
- Análisis de rollbacks y lecciones aprendidas
- Tendencias de métricas DORA

## Integración con CI/CD

El proceso de Change Management está integrado con GitHub Actions:

### Pipeline de Desarrollo (develop)
1. Push a rama develop
2. Ejecución automática de CI/CD:
   - Build y test
   - SonarQube analysis
   - Trivy security scan
   - Build de imagen Docker
   - Deploy automático a dev
   - Tests de integración

### Pipeline de Producción (main)
1. Pull Request de develop a main
2. Revisión y aprobación de PR
3. Merge a main dispara pipeline:
   - Build y test
   - SonarQube analysis
   - Trivy security scan
   - Build de imagen Docker
   - Creación de Git tag
   - Espera aprobación manual (deployment gate)
4. Aprobación manual en GitHub Actions
5. Deploy a producción
6. Generación de GitHub Release
7. Notificación a Slack
8. Tests E2E post-deployment

## Herramientas y Sistemas

### GitHub
- **Issues:** Registro de RFCs
- **Pull Requests:** Code reviews
- **Actions:** Automatización CI/CD
- **Releases:** Release management
- **Projects:** Tracking de cambios

### SonarQube
- Análisis de calidad de código
- Quality Gates
- Detección de code smells

### Trivy
- Escaneo de vulnerabilidades
- Análisis de imágenes Docker
- Compliance checks

### Slack
- Notificaciones de deployments
- Alertas de fallos
- Comunicación del equipo

### Azure Kubernetes Service (AKS)
- Despliegue de microservicios
- Rollout strategy
- Health monitoring

## Referencias

- Semantic Versioning: https://semver.org/
- Conventional Commits: https://www.conventionalcommits.org/
- ITIL Change Management: https://www.axelos.com/
- DORA Metrics: https://cloud.google.com/blog/products/devops-sre/using-the-four-keys-to-measure-your-devops-performance

## Historial de Cambios

| Versión | Fecha | Autor | Descripción |
|---------|-------|-------|-------------|
| 1.0.0 | 2024-11-29 | DevOps Team | Versión inicial del proceso de Change Management |
