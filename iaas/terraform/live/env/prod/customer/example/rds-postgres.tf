# Create additional private subnets for RDS
resource "aws_db_subnet_group" "rds_subnet_group" {
  name        = "rds-subnet-group"
  subnet_ids  = module.vpc.private_subnets
  description = "Subnet group for RDS"
}

# Create a security group for RDS
resource "aws_security_group" "rds_sg" {
  vpc_id = module.vpc.vpc_id

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]  # Allow access within the VPC
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]  # Allow outgoing traffic to anywhere
  }
}

resource "random_password" "db_password" {
  length           = 16
  special          = false       
  override_special = "" 
}

resource "random_pet" "db_secret_suffix" {}

resource "aws_secretsmanager_secret" "db_password_secret" {
  name        = "o2-rds-secr-${random_pet.db_secret_suffix.id}"
  description = "Database admin password for RDS instance"
}

resource "aws_secretsmanager_secret_version" "db_password_secret_version" {
  secret_id     = aws_secretsmanager_secret.db_password_secret.id
  secret_string = jsonencode({
    username = var.db_username
    password = random_password.db_password.result
  })
}

# RDS PostgreSQL instance in the newly created subnets
resource "aws_db_instance" "openobserve_rds" {
  allocated_storage    = 400
  engine               = "postgres"
  instance_class       = "db.m7g.large"
  identifier           = "openobserve"
  username             = var.db_username
  password             = random_password.db_password.result
  vpc_security_group_ids = [aws_security_group.rds_sg.id]
  db_subnet_group_name = aws_db_subnet_group.rds_subnet_group.name
  skip_final_snapshot  = true
}
