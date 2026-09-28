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
| **Qué se corrigió** | Se revisó que la IA esté ubicada como parte del núcleo del sistema (no como evolución futura), según indicación de la consigna. Se verificaron los costos estimados contra documentación oficial de AWS. Se ajustó el drawio XML para reflejar correctamente el flujo `s3:ObjectCreated → Lambda → Textract → Bedrock → Neon`. |

---

> Agregar nuevas entradas arriba de esta línea, en orden cronológico descendente.
