variable "aws_region" {
  type        = string
  description = "Primary AWS region"
  default     = "us-east-1"
}

variable "secondary_region" {
  type        = string
  description = "DR AWS region for cross-region backup copy"
  default     = "eu-west-1"
}

variable "aws_profile" {
  type        = string
  description = "AWS CLI profile for local Terraform runs (ignored when AWS_ACCESS_KEY_ID env var is set)"
  default     = "default"
}

variable "rds_username" {
  type        = string
  description = "Master username for the RDS database"
  default     = "fincorpadmin"
}

variable "rds_password" {
  type        = string
  description = "Master password for the RDS database — pass via -var or TF_VAR_rds_password; never hardcode"
  sensitive   = true
}
