output "aws_region" {
  value = var.aws_region
}

output "documents_bucket_name" {
  description = "Bucket privado de documentos"
  value       = aws_s3_bucket.documents.bucket
}

output "cognito_user_pool_id" {
  value = aws_cognito_user_pool.main.id
}

output "cognito_web_client_id" {
  description = "Client ID para el frontend (Next.js)"
  value       = aws_cognito_user_pool_client.web.id
}
