resource "aws_db_subnet_group" "db_subnet" {
  name       = var.db_subnet_name
  subnet_ids = var.private_subnets
}

resource "aws_db_instance" "replica" {
  replicate_source_db     = var.source_db_arn
  instance_class          = var.db_instance_class
  identifier              = "${var.db_identifier}-replica"
  db_subnet_group_name    = aws_db_subnet_group.db_subnet.name
  vpc_security_group_ids  = [var.db_security_group]
  skip_final_snapshot     = true
}


resource "null_resource" "update_secret" {
  triggers = {
    db_host = aws_db_instance.replica.address
  }

  provisioner "local-exec" {
    command = <<EOT
    aws secretsmanager put-secret-value \
      --region ${var.region} --secret-id ${var.secret_id} \
      --secret-string '{"username":"${var.db_username}","password":"${var.db_password}","dbname":"${var.db_name}",
       "port":"${var.db_port}",
        "host":"${aws_db_instance.replica.address}"
      }'
    EOT
    interpreter = ["/bin/bash", "-c"]
  }
  
}