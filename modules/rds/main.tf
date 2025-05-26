#
resource "aws_db_subnet_group" "db_subnet" {
  name       = var.db_subnet_name
  subnet_ids = var.private_subnets
}

resource "aws_db_instance" "postgres" {
  allocated_storage       = 10
  storage_type            = var.storage_type
  engine                  = var.db_engine
  instance_class          = var.db_instance_class
  identifier              = var.db_identifier
  username                = var.db_username
  password                = var.db_password
  vpc_security_group_ids  = [var.db_security_group]
  db_subnet_group_name    = aws_db_subnet_group.db_subnet.name
  db_name                 = var.db_name
  skip_final_snapshot     = true
  apply_immediately       = true
  backup_retention_period = 7
  deletion_protection     = false
}

#IAM Role for RDS Proxy
resource "aws_iam_role" "rds_proxy_secrets_manager_role" {
  name = "${var.db_identifier}-rds-proxy-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Principal = {
          Service = "rds.amazonaws.com"
        },
        Effect = "Allow",
        Sid    = ""
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "rds_proxy_secrets_access" {
  role       = aws_iam_role.rds_proxy_secrets_manager_role.name
  policy_arn = "arn:aws:iam::aws:policy/SecretsManagerReadWrite"
}
resource "aws_iam_role_policy" "rds_proxy_policy" {
  name = "${var.db_identifier}-rds-proxy-policy"
  role = aws_iam_role.rds_proxy_secrets_manager_role.id
  
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret",
          "rds:*",
          "rds-db:connect"
        ],
        Effect   = "Allow",
        Resource = "*"
      }
    ]
  })
}

# RDS Proxy
resource "aws_db_proxy" "postgres_proxy" {
  name                   = "${var.db_identifier}-proxy"
  role_arn               = aws_iam_role.rds_proxy_secrets_manager_role.arn
  vpc_subnet_ids         = var.private_subnets
  vpc_security_group_ids = [var.db_security_group]
  engine_family          =  var.engine_family

  auth {
    auth_scheme = "SECRETS"
    secret_arn  = var.secret_id
    iam_auth    = "DISABLED"
  }

}

resource "aws_db_proxy_default_target_group" "default" {
  db_proxy_name = aws_db_proxy.postgres_proxy.name
}


resource "aws_db_proxy_target" "rds_instance_target" {
  db_proxy_name       = aws_db_proxy.postgres_proxy.name
  target_group_name   = aws_db_proxy_default_target_group.default.name
  db_instance_identifier = aws_db_instance.postgres.identifier
}

resource "null_resource" "update_secret" {
  triggers = {
    db_host = aws_db_proxy.postgres_proxy.endpoint
  }

  provisioner "local-exec" {
    command = <<EOT
    aws secretsmanager put-secret-value \
      --secret-id ${var.secret_id} \
      --secret-string '{"username":"${var.db_username}","password":"${var.db_password}","dbname":"${var.db_name}",
       "port":"${var.db_port}",
        "host":"${aws_db_proxy.postgres_proxy.endpoint}"
      }'
    EOT
    interpreter = ["/bin/bash", "-c"]
  }
  
}
