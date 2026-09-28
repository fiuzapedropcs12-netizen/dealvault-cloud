-- migrate:up

-- Organizaciones (inmobiliarias / desarrolladoras). Cada una es un tenant del SaaS.
CREATE TABLE organizations (
    id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    name        text NOT NULL,
    created_at  timestamptz NOT NULL DEFAULT now()
);

-- Usuarios de la plataforma. La identidad la resuelve Cognito (cognito_sub).
-- organization_id es NULL para partes externas (comprador, escribano, banco...).
CREATE TABLE users (
    id               uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    cognito_sub      text NOT NULL UNIQUE,
    email            text NOT NULL UNIQUE,
    full_name        text,
    organization_id  uuid REFERENCES organizations(id),
    created_at       timestamptz NOT NULL DEFAULT now()
);

CREATE TYPE deal_status AS ENUM ('draft', 'open', 'closing', 'closed', 'cancelled');
CREATE TYPE currency_code AS ENUM ('USD', 'ARS');

-- Operación inmobiliaria: cada una tiene su propio deal room.
CREATE TABLE deals (
    id                uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    organization_id   uuid NOT NULL REFERENCES organizations(id),
    title             text NOT NULL,
    property_address  text,
    amount            numeric(18, 2) CHECK (amount >= 0),
    currency          currency_code NOT NULL DEFAULT 'USD',
    status            deal_status NOT NULL DEFAULT 'draft',
    created_by        uuid NOT NULL REFERENCES users(id),
    created_at        timestamptz NOT NULL DEFAULT now(),
    updated_at        timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX deals_organization_idx ON deals (organization_id);

CREATE TYPE party_role AS ENUM ('buyer', 'seller', 'notary', 'bank', 'agent');

-- Partes de cada operación. El rol es POR OPERACIÓN (no en Cognito):
-- una misma persona puede ser compradora en un deal y vendedora en otro.
-- Se invita por email; user_id se completa cuando la persona se registra.
CREATE TABLE deal_parties (
    id           uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    deal_id      uuid NOT NULL REFERENCES deals(id) ON DELETE CASCADE,
    email        text NOT NULL,
    user_id      uuid REFERENCES users(id),
    role         party_role NOT NULL,
    invited_at   timestamptz NOT NULL DEFAULT now(),
    accepted_at  timestamptz,
    UNIQUE (deal_id, email, role)
);

CREATE INDEX deal_parties_deal_idx ON deal_parties (deal_id);
CREATE INDEX deal_parties_user_idx ON deal_parties (user_id);

-- migrate:down

DROP TABLE deal_parties;
DROP TYPE party_role;
DROP TABLE deals;
DROP TYPE currency_code;
DROP TYPE deal_status;
DROP TABLE users;
DROP TABLE organizations;
