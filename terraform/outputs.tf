output "codeartifact_domain" {
  value = aws_codeartifact_domain.fincorp_domain.domain
}

output "codeartifact_npm_repository" {
  value = aws_codeartifact_repository.fincorp_npm.repository
}

output "codeartifact_pypi_repository" {
  value = aws_codeartifact_repository.fincorp_pypi.repository
}

output "ecr_repository_uri" {
  value = aws_ecr_repository.app_repo.repository_url
}

output "rds_endpoint" {
  value = aws_db_instance.fincorp_primary.endpoint
}

output "backup_vault_primary_arn" {
  description = "Primary AWS Backup vault ARN in us-east-1"
  value       = aws_backup_vault.fincorp_vault.arn
}

output "backup_vault_secondary_arn" {
  description = "DR AWS Backup vault ARN in us-west-2"
  value       = aws_backup_vault.fincorp_vault_secondary.arn
}

output "rds_security_group_id" {
  value = aws_security_group.rds_postgres.id
}
