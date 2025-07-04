# create alb security group
resource "aws_security_group" "frontend_alb_sg" {
  name        = var.frontend_alb_sg_name
  description = "Enable https and http on Port (80 and 443)"
  vpc_id      = var.vpc_id

  tags = {
    Name = var.frontend_alb_sg_name
  }
}

# create ingress rule
resource "aws_vpc_security_group_ingress_rule" "allow_http_alb" {
  description       = "Allow remote HTTP from anywhere"
  security_group_id = aws_security_group.frontend_alb_sg.id
  cidr_ipv4         = var.security_group_cidr
  from_port         = 80
  ip_protocol       = "tcp"
  to_port           = 80

  tags = {
    Name = "Security Groups to allow HTTP(80)"
  }
}

# create ingress rule
resource "aws_vpc_security_group_ingress_rule" "allow_https_alb" {
  description       = "Allow remote HTTPS from anywhere"
  security_group_id = aws_security_group.frontend_alb_sg.id
  cidr_ipv4         = var.security_group_cidr
  from_port         = 443
  ip_protocol       = "tcp"
  to_port           = 443

  tags = {
    Name = "Security Groups to allow HTTPS(443)"
  }
}

# create egress rule
resource "aws_vpc_security_group_egress_rule" "allow_all_outbound_alb" {
  security_group_id = aws_security_group.frontend_alb_sg.id
  cidr_ipv4         = var.security_group_cidr
  ip_protocol       = "-1"

  tags = {
    Name = "Allow all outbound"
  }
}

###############################
# create frontend service ecs security group
resource "aws_security_group" "frontend_service_sg" {
  name        = var.frontend_service_ecs_sg_name
  description = "Enable https from alb security group"
  vpc_id      = var.vpc_id

  tags = {
    Name = var.frontend_service_ecs_sg_name
  }
}

# create ingress rule
resource "aws_vpc_security_group_ingress_rule" "frontend_service_sg_ingress_rule" {
  description                  = "Allow HTTPS from alb"
  security_group_id            = aws_security_group.frontend_service_sg.id
  referenced_security_group_id = aws_security_group.frontend_alb_sg.id
  from_port                    = 443
  ip_protocol                  = "tcp"
  to_port                      = 443

  tags = {
    Name = var.frontend_service_ecs_sg_name
  }
}

# create ingress rule
resource "aws_vpc_security_group_ingress_rule" "frontend_service_sg_ingress_rule1" {
  description                  = "Allow HTTP from alb"
  security_group_id            = aws_security_group.frontend_service_sg.id
  referenced_security_group_id = aws_security_group.frontend_alb_sg.id
  from_port                    = 80
  ip_protocol                  = "tcp"
  to_port                      = 80

  tags = {
    Name = var.frontend_service_ecs_sg_name
  }
}

# create egress rule
resource "aws_vpc_security_group_egress_rule" "frontend_service_sg_egress_rule" {
  security_group_id = aws_security_group.frontend_service_sg.id
  cidr_ipv4         = var.security_group_cidr
  ip_protocol       = "-1"

  tags = {
    Name = "Allow all outbound"
  }
}

########################################### security group django service ###########################

# Get Route53 health check IP ranges
data "aws_ip_ranges" "route53_healthchecks" {
  services = ["ROUTE53_HEALTHCHECKS"]
}

# create django alb security group
resource "aws_security_group" "django_alb_sg" {
  name        = var.django_alb_sg_name
  description = "Enable https and http on Port (80 and 443)"
  vpc_id      = var.vpc_id

  tags = {
    Name = var.django_alb_sg_name
  }
}

# Route53 health check rules for Django ALB
resource "aws_vpc_security_group_ingress_rule" "allow_route53_healthcheck_django" {
  for_each = toset(data.aws_ip_ranges.route53_healthchecks.cidr_blocks)

  from_port         = 80
  to_port           = 80
  ip_protocol       = "tcp"
  cidr_ipv4         = each.value
  security_group_id = aws_security_group.django_alb_sg.id
  description       = "Allow Route 53 Health Check IPs for Django"

  tags = {
    Name = "Route53 Health Check - Django ALB"
  }
}

# create ingress rule
resource "aws_vpc_security_group_ingress_rule" "allow_http_django_alb_80" {
  description                  = "Allow remote HTTP from frontend service"
  security_group_id            = aws_security_group.django_alb_sg.id
  referenced_security_group_id = aws_security_group.frontend_service_sg.id
  from_port                    = 80
  ip_protocol                  = "tcp"
  to_port                      = 80

  tags = {
    Name = "Security Groups to allow HTTP(80)"
  }
}

# create ingress rule
resource "aws_vpc_security_group_ingress_rule" "allow_https_django_alb" {
  description                  = "Allow remote HTTPS from frontend service"
  security_group_id            = aws_security_group.django_alb_sg.id
  referenced_security_group_id = aws_security_group.frontend_service_sg.id
  from_port                    = 443
  ip_protocol                  = "tcp"
  to_port                      = 443

  tags = {
    Name = "Security Groups to allow HTTPS(443)"
  }
}

# create egress rule
resource "aws_vpc_security_group_egress_rule" "allow_all_outbound_alb_django" {
  security_group_id = aws_security_group.django_alb_sg.id
  cidr_ipv4         = var.security_group_cidr
  ip_protocol       = "-1"

  tags = {
    Name = "Allow all outbound"
  }
}

###############################
# create django service ecs security group
resource "aws_security_group" "django_service_sg" {
  name        = var.django_service_ecs_sg_name
  description = "Enable https from alb security group"
  vpc_id      = var.vpc_id

  tags = {
    Name = var.django_service_ecs_sg_name
  }
}

# create ingress rule
resource "aws_vpc_security_group_ingress_rule" "django_service_sg_ingress_rule" {
  description                  = "Allow HTTPS from alb"
  security_group_id            = aws_security_group.django_service_sg.id
  referenced_security_group_id = aws_security_group.django_alb_sg.id
  from_port                    = 443
  ip_protocol                  = "tcp"
  to_port                      = 443

  tags = {
    Name = var.django_service_ecs_sg_name
  }
}

# create ingress rule
resource "aws_vpc_security_group_ingress_rule" "django_service_sg_ingress_rule1" {
  description                  = "Allow HTTP from alb on port 8000"
  security_group_id            = aws_security_group.django_service_sg.id
  referenced_security_group_id = aws_security_group.django_alb_sg.id
  from_port                    = 8000
  ip_protocol                  = "tcp"
  to_port                      = 8000

  tags = {
    Name = var.django_service_ecs_sg_name
  }
}

# create egress rule
resource "aws_vpc_security_group_egress_rule" "django_service_sg_egress_rule" {
  security_group_id = aws_security_group.django_service_sg.id
  cidr_ipv4         = var.security_group_cidr
  ip_protocol       = "-1"

  tags = {
    Name = "Allow all outbound"
  }
}

########################################### security group flask service ###########################
# create flask alb security group
resource "aws_security_group" "flask_alb_sg" {
  name        = var.flask_alb_sg_name
  description = "Enable https and http on Port (80 and 443)"
  vpc_id      = var.vpc_id

  tags = {
    Name = var.flask_alb_sg_name
  }
}

# Route53 health check rules for Flask ALB
resource "aws_vpc_security_group_ingress_rule" "allow_route53_healthcheck_flask" {
  for_each = toset(data.aws_ip_ranges.route53_healthchecks.cidr_blocks)

  from_port         = 80
  to_port           = 80
  ip_protocol       = "tcp"
  cidr_ipv4         = each.value
  security_group_id = aws_security_group.flask_alb_sg.id
  description       = "Allow Route 53 Health Check IPs for Flask"

  tags = {
    Name = "Route53 Health Check - Flask ALB"
  }
}

# create ingress rule
resource "aws_vpc_security_group_ingress_rule" "allow_http_flask_alb_80" {
  description                  = "Allow remote HTTP from frontend service"
  security_group_id            = aws_security_group.flask_alb_sg.id
  referenced_security_group_id = aws_security_group.frontend_service_sg.id
  from_port                    = 80
  ip_protocol                  = "tcp"
  to_port                      = 80

  tags = {
    Name = "Security Groups to allow HTTP(80)"
  }
}

# create ingress rule
resource "aws_vpc_security_group_ingress_rule" "allow_https_flask_alb" {
  description                  = "Allow remote HTTPS from frontend service"
  security_group_id            = aws_security_group.flask_alb_sg.id
  referenced_security_group_id = aws_security_group.frontend_service_sg.id
  from_port                    = 443
  ip_protocol                  = "tcp"
  to_port                      = 443

  tags = {
    Name = "Security Groups to allow HTTPS(443)"
  }
}

# create egress rule
resource "aws_vpc_security_group_egress_rule" "allow_all_outbound_alb_flask" {
  security_group_id = aws_security_group.flask_alb_sg.id
  cidr_ipv4         = var.security_group_cidr
  ip_protocol       = "-1"

  tags = {
    Name = "Allow all outbound"
  }
}

###############################
# create flask service ecs security group
resource "aws_security_group" "flask_service_sg" {
  name        = var.flask_service_ecs_sg_name
  description = "Enable https from alb security group"
  vpc_id      = var.vpc_id

  tags = {
    Name = var.flask_service_ecs_sg_name
  }
}

# create ingress rule
resource "aws_vpc_security_group_ingress_rule" "flask_service_sg_ingress_rule" {
  description                  = "Allow HTTPS from alb"
  security_group_id            = aws_security_group.flask_service_sg.id
  referenced_security_group_id = aws_security_group.flask_alb_sg.id
  from_port                    = 443
  ip_protocol                  = "tcp"
  to_port                      = 443

  tags = {
    Name = var.flask_service_ecs_sg_name
  }
}

# create ingress rule
resource "aws_vpc_security_group_ingress_rule" "flask_service_sg_ingress_rule1" {
  description                  = "Allow HTTP from alb on port 5000"
  security_group_id            = aws_security_group.flask_service_sg.id
  referenced_security_group_id = aws_security_group.flask_alb_sg.id
  from_port                    = 5000
  ip_protocol                  = "tcp"
  to_port                      = 5000

  tags = {
    Name = var.flask_service_ecs_sg_name
  }
}

# create egress rule
resource "aws_vpc_security_group_egress_rule" "flask_service_sg_egress_rule" {
  security_group_id = aws_security_group.flask_service_sg.id
  cidr_ipv4         = var.security_group_cidr
  ip_protocol       = "-1"

  tags = {
    Name = "Allow all outbound"
  }
}

#############################################################
# create database security group for Flask
resource "aws_security_group" "flask_db_sg" {
  name        = var.flask_db_sg_name
  description = "Enable 3306 from ec2 security group"
  vpc_id      = var.vpc_id

  tags = {
    Name = var.flask_db_sg_name
  }
}

resource "aws_vpc_security_group_ingress_rule" "flask_db_sg_ingress_rule" {
  description                  = "Allow MySQL from Flask service"
  security_group_id            = aws_security_group.flask_db_sg.id
  referenced_security_group_id = aws_security_group.flask_service_sg.id
  from_port                    = 3306
  ip_protocol                  = "tcp"
  to_port                      = 3306

  tags = {
    Name = var.flask_db_sg_name
  }
}

resource "aws_vpc_security_group_ingress_rule" "flask_db_sg_ingress_rule1" {
  description                  = "Allow MySQL from same security group"
  security_group_id            = aws_security_group.flask_db_sg.id
  referenced_security_group_id = aws_security_group.flask_db_sg.id
  from_port                    = 3306
  ip_protocol                  = "tcp"
  to_port                      = 3306

  tags = {
    Name = var.flask_db_sg_name
  }
}

# create egress rule
resource "aws_vpc_security_group_egress_rule" "flask_db_sg_egress_rule" {
  security_group_id = aws_security_group.flask_db_sg.id
  cidr_ipv4         = var.security_group_cidr
  ip_protocol       = "-1"

  tags = {
    Name = "Allow all outbound"
  }
}

#############################################################
# create database security group for Django
resource "aws_security_group" "django_db_sg" {
  name        = var.django_db_sg_name
  description = "Enable 5432 from ec2 security group"
  vpc_id      = var.vpc_id

  tags = {
    Name = var.django_db_sg_name
  }
}

resource "aws_vpc_security_group_ingress_rule" "django_db_sg_ingress_rule" {
  description                  = "Allow PostgreSQL from Django service"
  security_group_id            = aws_security_group.django_db_sg.id
  referenced_security_group_id = aws_security_group.django_service_sg.id
  from_port                    = 5432
  ip_protocol                  = "tcp"
  to_port                      = 5432

  tags = {
    Name = var.django_db_sg_name
  }
}

resource "aws_vpc_security_group_ingress_rule" "django_db_sg_ingress_rule2" {
  description                  = "Allow PostgreSQL from same security group"
  security_group_id            = aws_security_group.django_db_sg.id
  referenced_security_group_id = aws_security_group.django_db_sg.id
  from_port                    = 5432
  ip_protocol                  = "tcp"
  to_port                      = 5432

  tags = {
    Name = var.django_db_sg_name
  }
}

# create egress rule
resource "aws_vpc_security_group_egress_rule" "django_db_sg_egress_rule" {
  security_group_id = aws_security_group.django_db_sg.id
  cidr_ipv4         = var.security_group_cidr
  ip_protocol       = "-1"

  tags = {
    Name = "Allow all outbound"
  }
}

################################
# create ec2 security group
resource "aws_security_group" "ec2_sg" {
  name        = var.ec2_sg_name
  description = "Enable https from alb security group"
  vpc_id      = var.vpc_id

  tags = {
    Name = var.ec2_sg_name
  }
}

# create ingress rule
resource "aws_vpc_security_group_ingress_rule" "ec2_sg_ingress_rule" {
  description       = "Allow HTTPS from anywhere"
  security_group_id = aws_security_group.ec2_sg.id
  cidr_ipv4         = var.security_group_cidr
  from_port         = 443
  ip_protocol       = "tcp"
  to_port           = 443

  tags = {
    Name = var.ec2_sg_name
  }
}

# create ingress rule
resource "aws_vpc_security_group_ingress_rule" "ec2_sg_ingress_rule1" {
  description       = "Allow HTTP from anywhere"
  security_group_id = aws_security_group.ec2_sg.id
  cidr_ipv4         = var.security_group_cidr
  from_port         = 80
  ip_protocol       = "tcp"
  to_port           = 80

  tags = {
    Name = var.ec2_sg_name
  }
}

# create ingress rule
resource "aws_vpc_security_group_ingress_rule" "ec2_sg_ingress_rule3" {
  description       = "Allow custom port 9090"
  security_group_id = aws_security_group.ec2_sg.id
  cidr_ipv4         = var.security_group_cidr
  from_port         = 9090
  ip_protocol       = "tcp"
  to_port           = 9090

  tags = {
    Name = var.ec2_sg_name
  }
}

# create ingress rule
resource "aws_vpc_security_group_ingress_rule" "ec2_sg_ingress_rule_2" {
  description       = "Allow remote SSH from anywhere"
  security_group_id = aws_security_group.ec2_sg.id
  cidr_ipv4         = var.security_group_cidr
  from_port         = 22
  ip_protocol       = "tcp"
  to_port           = 22

  tags = {
    Name = "Security Groups to allow SSH(22)"
  }
}

# create egress rule
resource "aws_vpc_security_group_egress_rule" "ec2_sg_egress_rule" {
  security_group_id = aws_security_group.ec2_sg.id
  cidr_ipv4         = var.security_group_cidr
  ip_protocol       = "-1"

  tags = {
    Name = "Allow all outbound"
  }
}