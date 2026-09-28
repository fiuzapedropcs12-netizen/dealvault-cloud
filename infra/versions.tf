terraform {
  required_version = ">= 1.8.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }

  # Por ahora el state es local (solo Pedro aplica cambios).
  # Próximo paso: migrar a un backend S3 con use_lockfile = true
  # para que cualquier integrante pueda aplicar sin pisarse.
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = var.project
      Environment = var.environment
      ManagedBy   = "OpenTofu"
    }
  }
}

data "aws_caller_identity" "current" {}

locals {
  name = "${var.project}-${var.environment}"
}
