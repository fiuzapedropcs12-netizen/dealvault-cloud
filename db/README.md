# Base de datos — DealVault

PostgreSQL serverless en **Neon** (región AWS `us-east-1`, la misma que el resto de la infra).
Migraciones en SQL plano con **dbmate**: el SQL es la fuente de verdad, independiente del ORM
que use el backend.

## Modelo

| Tabla | Para qué |
|---|---|
| `organizations` | Inmobiliarias / desarrolladoras (tenants del SaaS) |
| `users` | Usuarios, vinculados a Cognito por `cognito_sub` |
| `deals` | Operaciones inmobiliarias (cada una es un deal room) |
| `deal_parties` | Partes de cada operación y su **rol en esa operación** |
| `documents` / `document_versions` | Documentos y sus versiones (el archivo vive en S3; acá va la key y el SHA-256) |
| `document_permissions` | Permisos granulares por documento y parte (`view`, `download`, `sign`) |
| `signatures` | Firma electrónica sobre una versión exacta (hash) del documento |
| `audit_events` | Auditoría de negocio **append-only** (un trigger bloquea UPDATE, DELETE y TRUNCATE) |
| `document_extractions` | Resultado del procesamiento con IA (Textract + Bedrock) |

## Uso

Requisitos: Node.js (para correr dbmate con `npx`). Los comandos se corren
desde la carpeta `db/`.

```bash
cd db
cp .env.example .env        # pegar la connection string de Neon (sin pooling)
npx dbmate -d migrations --no-dump-schema status
npx dbmate -d migrations --no-dump-schema up
```

Para crear una migración nueva:

```bash
npx dbmate -d migrations new nombre_descriptivo
```

Las migraciones ya aplicadas **no se editan**: cualquier cambio va en una migración nueva.

**Nota:** si la connection string de Neon incluye `&channel_binding=require`,
hay que quitarlo; el driver de dbmate no soporta ese parámetro.