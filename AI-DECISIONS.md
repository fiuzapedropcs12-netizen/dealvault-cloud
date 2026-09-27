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