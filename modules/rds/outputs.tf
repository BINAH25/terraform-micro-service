output "db_hostname" {
  value = aws_db_instance.postgres.address
}

output "db_instance_arn" {
  value = aws_db_instance.postgres.arn
}
output "proxy_endpoint" {
  value = aws_db_proxy.postgres_proxy.endpoint
}