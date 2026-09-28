# Autenticación de usuarios.
# IMPORTANTE: Cognito solo resuelve QUIÉN es el usuario y su rol a nivel plataforma.
# El rol dentro de cada operación (comprador, vendedor, escribano, banco) se guarda
# en la base de datos, porque una misma persona puede ser compradora en un deal
# y vendedora en otro. Los permisos por documento se validan en el backend.

resource "aws_cognito_user_pool" "main" {
  name = "${local.name}-users"

  username_attributes      = ["email"]
  auto_verified_attributes = ["email"]

  mfa_configuration = "OPTIONAL"

  software_token_mfa_configuration {
    enabled = true
  }

  password_policy {
    minimum_length                   = 10
    require_lowercase                = true
    require_uppercase                = true
    require_numbers                  = true
    require_symbols                  = false
    temporary_password_validity_days = 7
  }

  account_recovery_setting {
    recovery_mechanism {
      name     = "verified_email"
      priority = 1
    }
  }

  # Para el MVP se usa el envío de mails propio de Cognito (límite diario bajo).
  # En producción se configuraría SES como remitente.
  email_configuration {
    email_sending_account = "COGNITO_DEFAULT"
  }

  deletion_protection = "INACTIVE"
}

resource "aws_cognito_user_pool_client" "web" {
  name         = "${local.name}-web"
  user_pool_id = aws_cognito_user_pool.main.id

  # Cliente público (Next.js): sin secret, login con SRP.
  generate_secret = false

  explicit_auth_flows = [
    "ALLOW_USER_SRP_AUTH",
    "ALLOW_REFRESH_TOKEN_AUTH",
  ]

  prevent_user_existence_errors = "ENABLED"
  enable_token_revocation       = true

  access_token_validity  = 60
  id_token_validity      = 60
  refresh_token_validity = 30

  token_validity_units {
    access_token  = "minutes"
    id_token      = "minutes"
    refresh_token = "days"
  }
}

# Roles a nivel plataforma.
locals {
  platform_groups = {
    admin        = "Administra la inmobiliaria/desarrolladora en la plataforma"
    agente       = "Crea y gestiona deal rooms"
    participante = "Parte externa invitada a una operación (comprador, vendedor, escribano, banco)"
  }
}

resource "aws_cognito_user_group" "platform" {
  for_each = local.platform_groups

  name         = each.key
  description  = each.value
  user_pool_id = aws_cognito_user_pool.main.id
}
