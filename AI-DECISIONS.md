# AI Decision Log — DealVault

Registro de código y decisiones de diseño generados con asistencia de IA,
con su validación y corrección humana.

---

## 1. Infraestructura base con OpenTofu (S3, Cognito, Budget)

**Fecha:** 27/09/2026 · **Autor:** Pedro Fiuza · **PR:** feat/infra-base

**Problema abordado:**
Crear la infraestructura inicial de forma reproducible (IaC) y con costo mínimo:
almacenamiento seguro de documentos, autenticación y control de gastos.

**Prompt / Herramienta:**
Claude — pedido de infraestructura en OpenTofu para un bucket S3 privado de
documentos, un User Pool de Cognito con roles y un budget de AWS.

**Código / Arquitectura generada:**
- Bucket S3 privado: bloqueo de acceso público, cifrado SSE-S3, versionado,
  política que rechaza acceso sin HTTPS, CORS para presigned URLs.
- Cognito User Pool con login por email, MFA opcional y grupos de plataforma.
- Budget mensual de 5 USD importado desde la consola al state de OpenTofu.

**Validación y corrección humana:**
- **Budget sin filtro de créditos (error de la IA):** el código generado no
  incluía el filtro que excluye créditos y reembolsos. Al revisar el
  `tofu plan` se vio que iba a eliminar ese filtro del budget existente. Con los
  créditos del free plan, el costo neto sería siempre 0 y las alertas nunca se
  dispararían. Se agregó el `filter_expression` antes de aplicar.
- **Roles por operación fuera de Cognito:** se descartó modelar comprador,
  vendedor, escribano y banco como grupos de Cognito, porque una misma persona
  puede tener roles distintos en distintas operaciones. Cognito maneja solo
  roles de plataforma; el rol por operación y los permisos por documento van en
  la base de datos y se validan en el backend.
- **Costo:** se eligió SSE-S3 en lugar de SSE-KMS con clave propia para evitar
  el costo fijo mensual de KMS en el MVP.

---

## 2. Diagrama de arquitectura y ARCHITECTURE.md

**Fecha:** 27/09/2026 · **Autor:** Joaquín Montes · **PR:** feat/architecture-diagram

**Problema abordado:**
Documentar la arquitectura cloud de DealVault para el Checkpoint 1: diagrama con
todos los componentes y justificación de cada decisión técnica.

**Prompt / Herramienta:**
Antigravity (Google DeepMind) — generar el diagrama de arquitectura AWS con Next.js/Vercel,
Cognito SRP, Route Handlers, Neon PostgreSQL, S3 privado (presigned URLs), pipeline de IA
(Lambda + Textract + Bedrock), SES, CloudWatch, GitHub Actions y OpenTofu, exportado como
PNG y drawio.

**Código / Arquitectura generada:**
- Diagrama en drawio y PNG con íconos de AWS y colores por capa.
- `docs/ARCHITECTURE.md` con tabla de decisiones por componente (qué se eligió, por qué,
  qué se descartó, costo estimado).

**Validación y corrección humana:**
- Se revisó que la IA esté ubicada como parte del núcleo del sistema (no como evolución
  futura), según indica la consigna.
- **Flujo del pipeline (error de la IA):** el diagrama generado tenía flechas de Textract a
  Bedrock y de Bedrock a Neon, sin pasar por la Lambda, que es la que orquesta. Se reemplazaron
  para