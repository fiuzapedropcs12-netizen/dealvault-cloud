-- migrate:up

CREATE TYPE document_type AS ENUM (
    'boleto', 'escritura', 'comprobante_fondos', 'tasacion', 'otro'
);

-- Documento lógico de una operación (ej: "Boleto de compraventa").
CREATE TABLE documents (
    id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    deal_id     uuid NOT NULL REFERENCES deals(id) ON DELETE CASCADE,
    type        document_type NOT NULL,
    title       text NOT NULL,
    created_by  uuid NOT NULL REFERENCES users(id),
    created_at  timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX documents_deal_idx ON documents (deal_id);

-- Cada archivo subido es una versión nueva; nunca se pisa.
-- El binario vive en S3; acá queda la referencia y el hash para verificar integridad.
CREATE TABLE document_versions (
    id             uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    document_id    uuid NOT NULL REFERENCES documents(id) ON DELETE CASCADE,
    version_no     integer NOT NULL CHECK (version_no > 0),
    s3_key         text NOT NULL,
    s3_version_id  text,
    sha256         char(64) NOT NULL,
    size_bytes     bigint NOT NULL CHECK (size_bytes > 0),
    mime_type      text NOT NULL,
    uploaded_by    uuid NOT NULL REFERENCES users(id),
    uploaded_at    timestamptz NOT NULL DEFAULT now(),
    UNIQUE (document_id, version_no)
);

CREATE TYPE document_permission AS ENUM ('view', 'download', 'sign');

-- Permisos granulares: qué parte de la operación puede hacer qué con cada documento.
-- El backend valida esta tabla ANTES de generar una presigned URL de S3.
CREATE TABLE document_permissions (
    document_id  uuid NOT NULL REFERENCES documents(id) ON DELETE CASCADE,
    party_id     uuid NOT NULL REFERENCES deal_parties(id) ON DELETE CASCADE,
    permission   document_permission NOT NULL,
    granted_by   uuid NOT NULL REFERENCES users(id),
    granted_at   timestamptz NOT NULL DEFAULT now(),
    PRIMARY KEY (document_id, party_id, permission)
);

CREATE INDEX document_permissions_party_idx ON document_permissions (party_id);

-- Firma electrónica (no firma digital en los términos de la Ley 25.506):
-- registra quién aceptó qué versión exacta (hash) y cuándo.
CREATE TABLE signatures (
    id                   uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    document_version_id  uuid NOT NULL REFERENCES document_versions(id),
    party_id             uuid NOT NULL REFERENCES deal_parties(id),
    signed_sha256        char(64) NOT NULL,
    signed_at            timestamptz NOT NULL DEFAULT now(),
    ip_address           inet,
    user_agent           text,
    UNIQUE (document_version_id, party_id)
);

-- migrate:down

DROP TABLE signatures;
DROP TABLE document_permissions;
DROP TYPE document_permission;
DROP TABLE document_versions;
DROP TABLE documents;
DROP TYPE document_type;
