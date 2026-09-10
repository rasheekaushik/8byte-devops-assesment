resource "aws_db_subnet_group" "main" {
  name = "${var.project_name}-db-subnet-group"

  subnet_ids = aws_subnet.private[*].id

  tags = {
    Name = "${var.project_name}-db-subnet-group"
  }
}

resource "aws_db_instance" "postgres" {
  identifier = "byte8-${var.project_name}-postgres"

  engine         = "postgres"
  engine_version = "17"

  instance_class = var.db_instance_class

  allocated_storage     = 20
  max_allocated_storage = 50
  storage_type          = "gp3"
  storage_encrypted     = true

  db_name  = var.db_name
  username = var.db_username
  password = var.db_password

  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.database.id]

  publicly_accessible = false

  backup_retention_period = 7
  backup_window           = "18:00-18:30"
  maintenance_window      = "sun:19:00-sun:19:30"

  skip_final_snapshot = true

  deletion_protection = false

  tags = {
    Name = "${var.project_name}-postgres"
  }
}
