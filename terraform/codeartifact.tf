resource "aws_codeartifact_domain" "fincorp_domain" {
  provider = aws.primary
  domain   = local.codeartifact_domain
  tags     = local.tags
}

# npm proxy — one external connection per repository is the AWS limit
resource "aws_codeartifact_repository" "fincorp_npm" {
  provider   = aws.primary
  repository = local.codeartifact_npm_repo
  domain     = aws_codeartifact_domain.fincorp_domain.domain

  external_connections {
    external_connection_name = "public:npmjs"
  }

  tags = local.tags
}

# pip proxy
resource "aws_codeartifact_repository" "fincorp_pypi" {
  provider   = aws.primary
  repository = local.codeartifact_pypi_repo
  domain     = aws_codeartifact_domain.fincorp_domain.domain

  external_connections {
    external_connection_name = "public:pypi"
  }

  tags = local.tags
}

resource "aws_codeartifact_repository_permissions_policy" "fincorp_npm_policy" {
  provider   = aws.primary
  domain     = aws_codeartifact_domain.fincorp_domain.domain
  repository = aws_codeartifact_repository.fincorp_npm.repository

  policy_document = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowAccountAccess"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${local.aws_account_id}:root"
        }
        Action = [
          "codeartifact:GetRepositoryEndpoint",
          "codeartifact:GetAuthorizationToken",
          "codeartifact:ReadFromRepository",
          "codeartifact:GetPackageVersionReadme",
          "codeartifact:DescribePackageVersion",
          "codeartifact:ListPackages",
          "codeartifact:ListPackageVersions",
          "codeartifact:ListPackageVersionAssets"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_codeartifact_repository_permissions_policy" "fincorp_pypi_policy" {
  provider   = aws.primary
  domain     = aws_codeartifact_domain.fincorp_domain.domain
  repository = aws_codeartifact_repository.fincorp_pypi.repository

  policy_document = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowAccountAccess"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${local.aws_account_id}:root"
        }
        Action = [
          "codeartifact:GetRepositoryEndpoint",
          "codeartifact:GetAuthorizationToken",
          "codeartifact:ReadFromRepository",
          "codeartifact:GetPackageVersionReadme",
          "codeartifact:DescribePackageVersion",
          "codeartifact:ListPackages",
          "codeartifact:ListPackageVersions",
          "codeartifact:ListPackageVersionAssets"
        ]
        Resource = "*"
      }
    ]
  })
}
