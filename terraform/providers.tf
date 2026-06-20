provider "aws" {
  alias               = "primary"
  region              = var.aws_region
  allowed_account_ids = ["195275642256"]
}

provider "aws" {
  alias               = "secondary"
  region              = var.secondary_region
  allowed_account_ids = ["195275642256"]
}
