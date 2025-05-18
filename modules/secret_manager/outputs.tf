output "db_username" {
  value = lookup(local.db_creds, "username", null)
}

output "db_password" {
  value = lookup(local.db_creds, "password", null)
}

output "db_port" {
  value = lookup(local.db_creds, "port", null)
}

output "db_name" {
  value = lookup(local.db_creds, "dbname", null)
}


output "secret_id" {
  value = data.aws_secretsmanager_secret.db_credentials.id
}

output "raw_secret" {
  value     = data.aws_secretsmanager_secret_version.db_credentials_version.secret_string
  sensitive = true
}

output "loki_url" {
  value = lookup(local.db_creds, "loki_url", null)
}
