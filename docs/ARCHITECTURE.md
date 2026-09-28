# DealVault — Arquitectura del Sistema

> **TPI — Desarrollo de Software Cloud — UTN FRLP 2026**

## Diagrama

El diagrama de arquitectura completo se encuentra en [`docs/architecture/dealvault-architecture.drawio`](./architecture/dealvault-architecture.drawio)  
Versión PNG exportada: [`docs/architecture/dealvault-architecture.png`](./architecture/dealvault-architecture.png)

---

## Flujo General

```
Usuario
  └─► Next.js (Vercel)
        ├─► Cognito (autenticación SRP)
        ├─► Route Handlers / API
        │     ├─► Neon PostgreSQL (deals, partes, permisos, auditoría, IA)
        │     └─► S3 privado (presigned URLs para subida/bajada)
        └─► SES (notificaciones por email)

S3 (evento PutObject)
  └─► Lambda OCR
        └─► Textract (extracción de texto)
              └─► Bedrock (análisis + detección de inconsistencias)
                    └─► Neon PostgreSQL (guarda resultados IA)

GitHub Actions ──► Vercel (deploy automático)
OpenTofu ──────► AWS (S3, Cognito, Lambda, SES, CloudWatch)
CloudWatch ─────► Logs, métricas y alarmas de toda la infra AWS
```

---

## Tabla de Decisiones por Componente

### Frontend

| Aspecto | Elegido | Por qué | Descartado | Costo estimado |
|---|---|---|---|---|
| **Framework** | Next.js 16 (App Router) | SSR/SSG nativo, route handlers actúan como API sin servidor extra, ecosistema maduro, soporte oficial en Vercel | Remix, SvelteKit | — |
| **Deploy** | Vercel | Free tier generoso, preview por PR, integración nativa con Next.js, deploy en segundos | AWS Amplify, EC2, ECS | USD 0 (Hobby) |
| **Auth cliente** | Cognito SRP (cliente sin secret) | No expone credenciales en el cliente, compatible con `amazon-cognito-identity-js`, tokens JWT | OAuth social, Auth0 | USD 0 (< 10k MAU) |

---

### Autenticación

| Aspecto | Elegido | Por qué | Descartado | Costo estimado |
|---|---|---|---|---|
| **Proveedor** | AWS Cognito | Integración nativa con S3 e IAM, free tier 10k MAU (nuevos user pools), MFA disponible | Auth0 (pricing escala rápido), Firebase Auth (lock-in Google) | USD 0 (< 10k MAU) |
| **Flujo** | SRP (`USER_SRP_AUTH`) | Contraseña nunca viaja en texto plano, compatible con app clients sin secret | `ALLOW_USER_PASSWORD_AUTH` (contraseña en claro) | — |
| **Autorización de recursos** | Roles en DB por operación | Granularidad fina por recurso, auditable, no depende de grupos de Cognito | Grupos de Cognito (menos flexibles), IAM por usuario | — |

---

### Base de Datos

| Aspecto | Elegido | Por qué | Descartado | Costo estimado |
|---|---|---|---|---|
| **Motor** | PostgreSQL 18 | Transacciones ACID, JSONB para metadatos IA, row-level security, `pgcrypto` | MySQL, DynamoDB (key-value no apto para relaciones complejas) | — |
| **Proveedor** | Neon (serverless Postgres) | Escala a cero, acceso público sin VPC, DB branching para PRs, free tier 0.5 GB; conexión en `db/.env` | RDS (requiere VPC + NAT Gateway ≈ **USD 30/mes** solo en networking), PlanetScale (solo MySQL) | USD 0 free tier vs RDS ~USD 35+/mes |
| **Connection pooling** | Neon Pooler (PgBouncer managed) | Lambdas abren muchas conexiones cortas; el pooler evita `too many connections` | RDS Proxy (USD 0.015/hora ≈ USD 11/mes extra) | USD 0 (incluido en Neon) |

---

### Almacenamiento de Documentos

| Aspecto | Elegido | Por qué | Descartado | Costo estimado |
|---|---|---|---|---|
| **Servicio** | AWS S3 | Durabilidad 11-nines, presigned URLs, triggers nativos para Lambda, integración con Textract | GCS, Azure Blob (rompen integración AWS) | USD 0.023/GB + USD 0.0004/1k req |
| **Acceso clientes** | Presigned URLs (PUT y GET) | El frontend nunca tiene credenciales AWS, URLs expiran (ej: 15 min), servidor controla acceso | URLs públicas (inseguro), proxy en servidor (consume RAM/ancho de banda) | — |
| **Cifrado en reposo** | SSE-S3 (AES-256) | Cero costo adicional, cumple requisitos de confidencialidad | SSE-KMS (USD 1/mes por clave + USD 0.03/10k ops, sin beneficio real a este volumen) | USD 0 vs SSE-KMS ~USD 1+/mes |
| **Acceso público** | Bloqueado (Block Public Access) | Documentos confidenciales, ningún objeto debe ser público | ACLs de bucket (deprecadas por AWS) | — |

---

### Pipeline de IA

| Aspecto | Elegido | Por qué | Descartado | Costo estimado |
|---|---|---|---|---|
| **Trigger** | Evento `s3:ObjectCreated:*` → Lambda | Asíncrono, no bloquea la carga, serverless, sin polling | SQS + worker EC2 (infraestructura extra innecesaria) | — |
| **OCR** | AWS Textract | Extrae texto, tablas y formularios de PDFs/imágenes, integración directa vía SDK, apto para docs legales complejos | Google Vision API (datos fuera de AWS), Tesseract self-hosted (baja precisión en PDFs escaneados) | USD 0.0015/pág (sin free tier — cuenta con créditos, no plan de 12 meses) |
| **LLM / Análisis** | Amazon Bedrock (Claude 3 Haiku/Sonnet) | API unificada, sin gestión de GPU, datos no salen de AWS (compliance), acceso a Claude con baja latencia | OpenAI API (datos salen de AWS), SageMaker (endpoints de costo fijo) | Haiku: ~USD 0.00025/1k input tokens |
| **Persistencia IA** | Tabla `document_extractions` en Neon | Centraliza en un motor, permite joins con deals/documentos, historial auditable | DynamoDB separado (complejidad extra, joins imposibles) | USD 0 (Neon free tier) |

---

### Notificaciones

| Aspecto | Elegido | Por qué | Descartado | Costo estimado |
|---|---|---|---|---|
| **Servicio** | AWS SES | Stack AWS unificado, alta deliverability, soporta HTML templates | SendGrid (USD 19.95/mes), SNS email (no soporta HTML) | USD 0.10/1k emails (sin free tier de 62k — ese beneficio era exclusivo del sandbox desde EC2/Lambda en cuentas elegibles; nuestra cuenta usa créditos) |

> **Nota:** Lambda y SES aún no están desplegados en `infra/`; la integración es parte del roadmap.

---

### Observabilidad

| Aspecto | Elegido | Por qué | Descartado | Costo estimado |
|---|---|---|---|---|
| **Logs y métricas** | AWS CloudWatch | Integración automática con Lambda, S3, Cognito y SES; alarmas y dashboards nativos | Datadog (USD 15/host/mes), ELK self-hosted (infra compleja) | USD 0 (free tier: 5 GB logs, 10 métricas custom/mes) |
| **Alertas** | CloudWatch Alarms + SNS | Alertas sobre errores de Lambda, latencia y Textract failures | PagerDuty (costo adicional) | USD 0 (primeras 10 alarmas gratis) |

---

### Infraestructura como Código

| Aspecto | Elegido | Por qué | Descartado | Costo estimado |
|---|---|---|---|---|
| **Tool** | OpenTofu | Fork open-source de Terraform (MPL-2.0), compatible con todos los providers AWS, sin lock-in de HashiCorp | Terraform (BSL desde v1.6), CDK (requiere TypeScript para HCL equivalente), CloudFormation (verboso, no portable) | USD 0 |
| **State backend** | Local (actual) → S3 + `use_lockfile` (pendiente) | Hoy el state es local para agilizar el arranque; la migración a S3 con `use_lockfile` está pendiente. DynamoDB ya no es necesario con OpenTofu ≥ 1.10. | State en repositorio (inseguro, no escalable) | USD ~0 (volúmenes mínimos) |

---

### CI/CD

| Aspecto | Elegido | Por qué | Descartado | Costo estimado |
|---|---|---|---|---|
| **Pipeline** | GitHub Actions | Integrado con el repo, 2000 min/mes gratis, ecosistema amplio, workflows en YAML versionados | CircleCI, Jenkins (infra propia), GitLab CI (cambio de plataforma) | USD 0 (< 2000 min/mes) |
| **Deploy frontend** | Vercel (automático por push) | Integración nativa con GitHub, sin action de deploy manual | Deploy manual via AWS CLI en Actions | USD 0 |
| **Validaciones CI** | Lint + build Next.js + `tofu validate` | Detecta errores antes de mergear, protege main | Solo tests manuales | — |

---

## Estructura del Repositorio

```
dealvault-cloud/
├── apps/
│   └── web/              # Next.js 16 (Maxo)
├── infra/                # OpenTofu — S3, Cognito (Pedro) [Lambda y SES: pendiente]
├── db/                   # Schema PostgreSQL + migraciones (Pedro) · conexión en db/.env
├── docs/
│   ├── ARCHITECTURE.md   # Este archivo (Joaco — issue #4)
│   └── architecture/
│       ├── dealvault-architecture.drawio
│       └── dealvault-architecture.png
├── AI-DECISIONS.md       # Registro de uso de IA (requerido por cátedra)
├── .github/
│   ├── pull_request_template.md
│   └── workflows/        # GitHub Actions CI (Joaco — issue #2)
└── README.md
```

---

## Servicios externos y límites

> Los servicios marcados como **[Externo]** corren fuera del límite de AWS Cloud / us-east-1.

| Servicio | Tipo | Nota |
|---|---|---|
| Next.js / Vercel | **[Externo]** | Deploy automático vía GitHub Actions |
| Neon PostgreSQL | **[Externo]** | Serverless Postgres; conexión en `db/.env` |
| GitHub Actions | **[Externo]** | CI/CD: lint, build, `tofu validate`; dispara deploy en Vercel |
| OpenTofu | Tooling local/CI | Provisiona S3, Cognito en `us-east-1`; state local (pendiente migrar a S3) |
| CloudWatch | AWS (us-east-1) | Recibe logs y métricas de Lambda, S3 eventos, Cognito y SES automáticamente |
| S3 Bucket | AWS (us-east-1) | `dealvault-dev-docs-*` (privado, SSE-S3) |

> **Seguridad:** Los IDs de Cognito (User Pool y Client) se manejan como variables de entorno y no se documentan en este archivo. El repositorio es público.
