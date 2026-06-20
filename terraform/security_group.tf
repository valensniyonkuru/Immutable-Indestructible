data "aws_vpc" "default" {
  provider = aws.primary
  default  = true
}

data "aws_subnets" "default" {
  provider = aws.primary

  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }

  filter {
    name   = "default-for-az"
    values = ["true"]
  }
}

resource "aws_security_group" "rds_postgres" {
  provider    = aws.primary
  name        = "fincorp-rds-postgres-sg"
  description = "Allow PostgreSQL access from within the VPC only"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.default.cidr_block]
    description = "PostgreSQL from VPC CIDR"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }

  tags = merge(local.tags, {
    Name = "fincorp-rds-postgres-sg"
  })
}
