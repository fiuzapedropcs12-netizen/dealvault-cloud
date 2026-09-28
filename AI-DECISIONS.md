# AI-DECISIONS.md

Registro de uso de herramientas de IA en el proyecto, según requisito de la cátedra.

---

## Formato de entrada

| Campo | Descripción |
|---|---|
| **Fecha** | Cuándo se usó la IA |
| **Autor** | Integrante del equipo |
| **Issue** | Número de issue relacionado |
| **Herramienta** | Qué IA se utilizó |
| **Prompt / Tarea** | Qué se le pidió |
| **Qué generó** | Output de la IA |
| **Qué se corrigió** | Cambios manuales sobre lo generado |

---

## Entradas

### 2026-09-27 — Joaco — issue #4 (arquitectura)

| Campo | Detalle |
|---|---|
| **Herramienta** | Antigravity (Google DeepMind) |
| **Prompt / Tarea** | Generar diagrama de arquitectura AWS para DealVault con todos los componentes del sistema: Next.js/Vercel, Cognito SRP, Route Handlers, Neon PostgreSQL, S3 privado (presigned URLs), pipeline IA (Lambda + Textract + Bedrock), SES, CloudWatch, GitHub Actions, OpenTofu. Exportar como PNG y drawio. |
| **Qué generó** | Imagen PNG del diagrama con íconos de AWS, colores por capa (usuario, core, pipeline IA, soporte), leyenda. Archivo XML drawio con todos los nodos y conexiones. `docs/ARCHITECTURE.md` con tabla de decisiones por componente (qué elegimos / por qué / qué descartamos / costo estimado). |
| **Qué se corrigió** | Se revisó que la IA esté ubicada como parte del núcleo del sistema (no como evolución futura), según indicación de la consigna. Se ajustó el drawio XML para reflejar correctamente el flujo `s3:ObjectCreated → Lambda → Textract → Bedrock → Neon`. **Nota:** los costos iniciales no fueron validados contra documentación oficial; errores detectados en revisión de PR #10 y corregidos en la entrada siguiente. |

---

### 2026-09-27 — Joaco — issue #4 / PR #10 (correcciones de revisión)

**Problema:** La revisión de PR #10 detectó errores en datos técnicos (versiones, nombre de tabla, estado del backend de OpenTofu, nombre del bucket, IDs sensibles expuestos) y en los costos estimados (free tier de Cognito, SES y Textract incorrecto para nuestra cuenta). Además, el diagrama tenía flechas del pipeline de IA que iban de Textract y Bedrock directamente a Neon, sin pasar por Lambda (que es el orquestador real).

**Prompt / Tarea:** Corregir `docs/ARCHITECTURE.md` y `docs/architecture/dealvault-architecture.drawio` para que coincidan con lo construido: versiones reales (Next.js 16, Postgres 18), tabla `document_extractions`, state de OpenTofu local (pendiente S3), bucket `dealvault-dev-docs-*`, costos correctos (Cognito 10k MAU, sin free tier de SES ni Textract para cuentas con créditos), eliminar IDs de Cognito del doc público. Corregir flechas del pipeline para que salgan de Lambda hacia Textract, Lambda hacia Bedrock y Lambda hacia Neon. Agregar esta entrada a AI-DECISIONS.md con el formato de la consigna.

**Output:** Se actualizaron `ARCHITECTURE.md` (7 secciones de tabla corregidas, sección de configuración reemplazada por tabla de servicios externos/límites sin IDs sensibles) y el `.drawio` (5 flechas reemplazadas para que Lambda orqueste el pipeline, con labels numerados 1-5).

**Validación:** Revisada documentación oficial: AWS Cognito (free tier nuevos user pools: 10.000 MAU), AWS Textract (sin free tier permanente en cuentas con créditos — el período de 12 meses aplica solo al plan Free Tier), AWS SES (el beneficio de 62k emails desde Lambda/EC2 fue discontinuado). Flujo del diagrama validado contra la lógica de la Lambda: `S3 event → Lambda → Textract SDK call → Lambda recibe texto → Bedrock SDK call → Lambda recibe análisis → INSERT en document_extractions (Neon)`.

---

> Agregar nuevas entradas arriba de esta línea, en orden cronológico descendente.
