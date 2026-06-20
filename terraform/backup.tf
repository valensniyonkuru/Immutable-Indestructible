resource "aws_backup_vault" "fincorp_vault" {
  provider = aws.primary
  name     = local.backup_vault_name
  tags     = local.tags
}

resource "aws_backup_vault" "fincorp_vault_secondary" {
  provider = aws.secondary
  name     = "${local.backup_vault_name}-dr"
  tags     = local.tags
}

resource "aws_backup_plan" "fincorp_plan" {
  provider = aws.primary
  name     = local.backup_plan_name

  rule {
    rule_name         = local.daily_backup_rule
    target_vault_name = aws_backup_vault.fincorp_vault.name
    schedule          = "cron(0 5 * * ? *)"

    lifecycle {
      delete_after = 30
    }

    recovery_point_tags = {
      Project = "fincorp"
      Role    = "dr-backup"
    }

    copy_action {
      destination_vault_arn = aws_backup_vault.fincorp_vault_secondary.arn
      lifecycle {
        delete_after = 30
      }
    }
  }

  tags = local.tags
}

resource "aws_backup_selection" "fincorp_selection" {
  provider     = aws.primary
  name         = "fincorp-rds-selection"
  plan_id      = aws_backup_plan.fincorp_plan.id
  iam_role_arn = aws_iam_role.aws_backup_role.arn

  resources = [
    aws_db_instance.fincorp_primary.arn
  ]
}
