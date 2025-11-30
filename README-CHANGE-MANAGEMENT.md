# Sistema de Change Management y Release Notes

Este repositorio contiene el sistema completo de gestión de cambios, release notes automáticas y procedimientos de rollback para la plataforma de microservicios.

## Documentación Principal

### Procesos y Procedimientos

- **[CHANGE-MANAGEMENT.md](CHANGE-MANAGEMENT.md)** - Proceso formal de gestión de cambios
- **[ROLLBACK-PLAN.md](ROLLBACK-PLAN.md)** - Procedimientos detallados de rollback
- **[CHANGELOG.md](CHANGELOG.md)** - Historial de cambios del pipeline template

### Workflows y Templates

- **[microservice-cicd.yml](.github/workflows/microservice-cicd.yml)** - Pipeline reutilizable CI/CD
- **[rollback.yml](.github/workflows/rollback.yml)** - Workflow manual de rollback
- **[RFC Template](.github/ISSUE_TEMPLATE/rfc-template.md)** - Plantilla para solicitud de cambios

### Scripts

- **[rollback-service.sh](scripts/rollback-service.sh)** - Script bash para rollback automatizado

## Características Implementadas

### Gestión de Cambios (Change Management)

El sistema implementa un proceso formal basado en ITIL que clasifica los cambios en cuatro categorías:

- **Standard:** Cambios de bajo riesgo con procedimientos preestablecidos
- **Normal:** Cambios que requieren evaluación y aprobación formal
- **Major:** Cambios significativos con alto impacto
- **Emergency:** Cambios urgentes para resolver incidentes críticos

Cada tipo tiene sus propios requisitos de aprobación y procedimientos.

### Release Notes Automáticas

El pipeline genera automáticamente release notes en cada deployment a producción:

- Analiza commits usando Conventional Commits
- Categoriza cambios (Features, Bug Fixes, Breaking Changes, etc.)
- Crea GitHub Release con release notes
- Actualiza CHANGELOG.md automáticamente
- Incluye información de deployment e instrucciones de rollback

### Sistema de Etiquetado Mejorado

Los tags Git se crean con metadata completa:

- Versión semántica (v1.2.3)
- Información del servicio y ambiente
- Fecha de build
- Commit SHA y autor
- Link al workflow run
- Tag de imagen Docker

### Rollback Automatizado

Múltiples opciones para ejecutar rollback:

1. **Workflow de GitHub Actions:** Interfaz gráfica con validaciones
2. **Script bash:** `rollback-service.sh` con verificaciones automáticas
3. **kubectl directo:** Para rollback urgente

## Uso Rápido

### Realizar un Cambio

```bash
# 1. Crear feature branch
git checkout develop
git pull
git checkout -b feature/nueva-funcionalidad

# 2. Desarrollar con Conventional Commits
git commit -m "feat: agregar búsqueda de productos"
git commit -m "fix: corregir validación de email"

# 3. Push y crear PR
git push origin feature/nueva-funcionalidad

# 4. Merge a develop → deploy automático a dev

# 5. Para producción: PR de develop a main → aprobación → deploy
```

### Ejecutar Rollback

**Opción 1: GitHub Actions (Recomendado)**

```
1. GitHub → Actions → "Rollback to Previous Version"
2. Run workflow
3. Seleccionar servicio, ambiente, versión objetivo
4. Ingresar razón del rollback
5. Confirmar
```

**Opción 2: Script**

```bash
./scripts/rollback-service.sh user-service prod v1.2.0
```

**Opción 3: kubectl**

```bash
kubectl rollout undo deployment/user-service -n ecommerce-prod
```

### Conventional Commits

Todos los commits deben seguir este formato para release notes automáticas:

```bash
# Feature (incrementa MINOR: 1.2.0 → 1.3.0)
git commit -m "feat: agregar autenticación con OAuth"

# Bug fix (incrementa PATCH: 1.2.0 → 1.2.1)
git commit -m "fix: resolver timeout en pagos"

# Breaking change (incrementa MAJOR: 1.2.0 → 2.0.0)
git commit -m "feat!: migrar a nueva API

BREAKING CHANGE: Endpoints v1 deprecados"

# Otros tipos: docs, style, refactor, perf, test, chore, ci
```

## Flujo de Trabajo

### Desarrollo (develop → dev)

```
Commit → Push → PR → Merge a develop
           ↓
    Deploy automático a dev
           ↓
    Tag: v1.2.3-dev
```

### Producción (main → prod)

```
PR develop → main → Merge
           ↓
    Pipeline CI/CD
           ↓
    ⏸️ Aprobación Manual
           ↓
    Deploy a prod
           ↓
    Tag: v1.2.3
           ↓
    GitHub Release creado
           ↓
    CHANGELOG.md actualizado
```

## Criterios de Aceptación Cumplidos

- ✅ Proceso formal de Change Management definido y documentado
- ✅ Generación automática de Release Notes implementada
- ✅ Sistema de etiquetado (tagging) mejorado con metadata
- ✅ Planes de rollback documentados e implementados

## Requisitos

### Para Usar el Pipeline

- Repositorio debe ser parte de la organización `IngesoftV-backend-microservices`
- Secrets configurados a nivel de organización (ver SETUP.md)
- Environments `dev` y `prod` configurados
- Conventional Commits en todos los commits

### Para Rollback

- Azure CLI instalado y autenticado
- kubectl instalado
- Acceso al cluster AKS correspondiente
- Permisos para ejecutar workflows manuales (prod)

## Ejemplos

### Ejemplo de RFC

Ver `.github/ISSUE_TEMPLATE/rfc-template.md` para plantilla completa.

### Ejemplo de Release Notes Generadas

```markdown
## Release v1.3.0

**Service:** user-service
**Date:** 2024-11-29 22:00:00 UTC
**Environment:** prod

### Changes

### ✨ Features
- agregar autenticación con OAuth (a1b2c3d)
- implementar caché de sesiones (e4f5g6h)

### 🐛 Bug Fixes
- resolver timeout en login (i7j8k9l)

### 📦 Deployment Information
- **Docker Image:** `acrvingesoftprod.azurecr.io/user-service:v1.3.0`
- **Commit SHA:** `abc123...`
- **Triggered by:** @developer

### 🔄 Rollback Instructions
...
```

## Estructura de Archivos

```
pipeline-templates/
├── CHANGE-MANAGEMENT.md          # Proceso formal de cambios
├── ROLLBACK-PLAN.md              # Procedimientos de rollback
├── CHANGELOG.md                  # Historial de cambios
├── README.md                     # Este archivo
├── SETUP.md                      # Guía de configuración
├── ARCHITECTURE.md               # Arquitectura del pipeline
├── .github/
│   ├── ISSUE_TEMPLATE/
│   │   └── rfc-template.md       # Template RFC
│   └── workflows/
│       ├── microservice-cicd.yml # Pipeline CI/CD principal
│       └── rollback.yml          # Workflow de rollback
├── scripts/
│   └── rollback-service.sh       # Script de rollback
└── examples/
    ├── ci-dev.yml                # Ejemplo workflow dev
    └── ci-prod.yml               # Ejemplo workflow prod
```

## Métricas DORA

El sistema facilita la medición de métricas DORA:

- **Deployment Frequency:** Ver GitHub Releases
- **Lead Time for Changes:** Tiempo entre commit y deploy
- **Change Failure Rate:** Issues con label `rollback` / Total releases
- **Mean Time to Recovery:** Duración promedio de rollbacks

## Mejores Prácticas

### Desarrolladores
- Usar Conventional Commits siempre
- Crear RFC para cambios Normal o Major
- Escribir tests antes de PR
- Documentar cambios en código

### Tech Leads
- Revisar RFCs cuidadosamente
- Validar planes de rollback
- Aprobar deployments conscientemente
- Conducir post-mortems

### DevOps
- Monitorear pipelines activamente
- Mantener scripts actualizados
- Optimizar tiempos de deployment
- Revisar métricas mensualmente

## Troubleshooting

Ver sección de Troubleshooting en:
- CHANGE-MANAGEMENT.md
- ROLLBACK-PLAN.md

## Soporte

- **Issues:** Crear issue con label `change-management`
- **Slack:** #devops-support
- **Documentación:** Ver archivos .md en este repositorio

## Referencias

- [Conventional Commits](https://www.conventionalcommits.org/)
- [Semantic Versioning](https://semver.org/)
- [Keep a Changelog](https://keepachangelog.com/)
- [ITIL Change Management](https://www.axelos.com/)
- [DORA Metrics](https://www.devops-research.com/research.html)

---

**Versión:** 1.0.0  
**Fecha:** 2025-11-29  
**Autores:** DevOps Team - IngesoftV
