# Infraestructura — DealVault

Infraestructura como código con **OpenTofu** sobre AWS (`us-east-1`).

## Qué crea

| Recurso | Para qué |
|---|---|
| S3 `dealvault-dev-docs-*` | Documentos de cada operación. Privado, cifrado (SSE-S3), versionado, solo HTTPS, CORS para presigned URLs |
| Cognito User Pool + cliente web | Login de usuarios. Grupos de plataforma: `admin`, `agente`, `participante` |
| AWS Budget mensual | Alerta de costo al 80% real y 100% pronosticado |

Los roles por operación (comprador, vendedor, escribano, banco) y los permisos por documento
**no** viven en Cognito: se guardan en la base de datos y se validan en el backend.

## Uso

Requisitos: AWS CLI configurada (`aws sts get-caller-identity`) y OpenTofu >= 1.8.

```bash
cd infra
cp terraform.tfvars.example terraform.tfvars   # completar el mail
tofu init
tofu plan
tofu apply
tofu output
```

## Pendiente

- Migrar el state local a un backend S3 con lockfile para que cualquier integrante pueda aplicar.
- Roles IAM de mínimo privilegio para las Lambdas.
