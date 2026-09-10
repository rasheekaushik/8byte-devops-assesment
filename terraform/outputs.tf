output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id
}

output "public_subnet_ids" {
  description = "IDs of the public subnets"
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "IDs of the private subnets"
  value       = aws_subnet.private[*].id
}

output "alb_dns_name" {
  description = "DNS name of the application load balancer"
  value       = aws_lb.app.dns_name
}

output "ec2_instance_id" {
  description = "ID of the application EC2 instance"
  value       = aws_instance.app.id
}

output "rds_endpoint" {
  description = "Endpoint of the PostgreSQL RDS instance"
  value       = aws_db_instance.postgres.endpoint
}

output "rds_database_name" {
  description = "PostgreSQL database name"
  value       = aws_db_instance.postgres.db_name
}
