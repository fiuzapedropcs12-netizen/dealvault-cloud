variable "project" {
  description = "Nombre del proyecto, usado como prefijo de recursos"
  type        = string
  default     = "dealvault"
}

variable "environment" {
  description = "Entorno de despliegue"
  type        = string
  default     = "dev"
}

variable "aws_region" {
  description = "Región de AWS (us-east-1 por disponibilidad de Bedrock/Textract y costo)"
  type        = string
  default     = "us-east-1"
}

variable "budget_email" {
  description = "Mail que recibe las alertas de costo"
  type        = string
}

variable "budget_limit_usd" {
  description = "Límite mensual de gasto en USD"
  type        = number
  default     = 5
}

variable "budget_name" {
  description = "Nombre del budget (debe coincidir con el creado a mano para importarlo)"
  type        = string
  default     = "dealvault-monthly"
}

variable "allowed_origins" {
  description = "Orígenes permitidos por CORS para subir/bajar documentos con presigned URLs"
  type        = list(string)
  default     = ["http://localhost:3000"]
}
