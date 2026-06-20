terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

locals {
  aws_account_id   = "195275642256"
  project          = "fincorp-immutable-indestructible"
  region_primary   = "us-east-1"
  region_secondary = "eu-west-1"

  codeartifact_domain    = "fincorp-domain"
  codeartifact_npm_repo  = "fincorp-npm-proxy"
  codeartifact_pypi_repo = "fincorp-pypi-proxy"

  ecr_repository = "fincorp-app-repo"

  backup_vault_name = "fincorp-backup-vault"
  backup_plan_name  = "fincorp-backup-plan"
  daily_backup_rule = "daily-backup-rule"

  rds_identifier        = "fincorp-rds-primary"
  rds_instance_class    = "db.t4g.small"
  rds_engine            = "postgres"
  rds_engine_version    = "16.3"
  rds_allocated_storage = 20
  rds_name              = "fincorpdb"

  tags = {
    Project     = local.project
    Environment = "production"
    ManagedBy   = "Terraform"
  }
}
