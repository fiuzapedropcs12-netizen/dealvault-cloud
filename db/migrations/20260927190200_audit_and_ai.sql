-- migrate:up

-- Registro de auditoría de negocio: quién vio, descargó, subió o firmó qué y cuándo.
-- Es un dato de negocio, no un log operativo (eso va a CloudWatch).
-- Append-only: el trigger de abajo impide modificar o borrar filas.
CREATE TABLE audit_events (
    id             bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    occurred_at    timestamptz NOT NULL DEFAULT now(),
    actor_user_id  uuid REFERENCES users(id),
    deal_id        uuid REFERENCES deals(id),
    document_id    uuid REFERENCES documents(id),
    action         text NOT NULL,
    ip_address     inet,
    metadata       jsonb NOT NULL DEFAULT '{}'::jsonb
);

CREATE INDEX audit_events_deal_time_idx ON audit_events (deal_id, occurred_at);
CREATE INDEX audit_events_document_idx ON audit_events (document_id);

CREATE FUNCTION audit_events_block_mutation() RETURNS trigger AS $$
BEGIN
    RAISE EXCEPTION 'audit_events es append-only: no se permite %', TG_OP;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER audit_events_no_update_delete
    BEFORE UPDATE OR DELETE ON audit_events
    FOR EACH ROW EXECUTE FUNCTION audit_events_block_mutation();

CREATE TRIGGER audit_events_no_truncate
    BEFORE TRUNCATE ON audit_events
    FOR EACH STATEMENT EXECUTE FUNCTION audit_events_block_mutation();

CREATE TYPE extraction_status AS ENUM ('pending', 'processing', 'done', 'failed');

-- Resultado del procesamiento con IA (Textract + Bedrock) de cada versión de documento:
-- datos estructurados extraídos y alertas de inconsistencia entre documentos.
CREATE TABLE document_extractions (
    id                   uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    document_version_id  uuid NOT NULL UNIQUE REFERENCES document_versions(id) ON DELETE CASCADE,
    status               extraction_status NOT NULL DEFAULT 'pending',
    extracted_data       jsonb,
    warnings             jsonb NOT NULL DEFAULT '[]'::jsonb,
    model_id             text,
    error_message        text,
    created_at           timestamptz NOT NULL DEFAULT now(),
    completed_at         timestamptz
);

-- migrate:down

DROP TABLE document_extractions;
DROP TYPE extraction_status;
DROP TRIGGER audit_events_no_truncate ON audit_events;
DROP TRIGGER audit_events_no_update_delete ON audit_events;
DROP TABLE audit_events;
DROP FUNCTION audit_events_block_mutation();
