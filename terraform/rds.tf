resource "aws_db_subnet_group" "fincorp_subnet" {
  provider   = aws.primary
  name       = "fincorp-rds-subnet-group"
  subnet_ids = data.aws_subnets.default.ids

  tags = {
    Name    = "fincorp-rds-subnet-group"
    Project = "fincorp"
  }
}

resource "aws_db_instance" "fincorp_primary" {
  provider             = aws.primary
  identifier           = local.rds_identifier
  engine               = local.rds_engine
  engine_version       = local.rds_engine_version
  instance_class       = local.rds_instance_class
  db_name              = local.rds_name
  allocated_storage    = local.rds_allocated_storage
  username             = var.rds_username
  password             = var.rds_password
  publicly_accessible  = false
  backup_retention_period = 7
  skip_final_snapshot  = true
  deletion_protection  = false
  db_subnet_group_name = aws_db_subnet_group.fincorp_subnet.name
  vpc_security_group_ids = [aws_security_group.rds_postgres.id]

  tags = {
    Name    = "fincorp-rds-primary"
    Project = "fincorp"
  }
}
