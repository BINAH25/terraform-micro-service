region              = "us-east-1"
vpc_cidr            = "12.0.0.0/16"
vpc_name            = "micro-service-proj-us-east-1-vpc"
cidr_public_subnet  = ["12.0.1.0/24", "12.0.2.0/24"]
cidr_private_subnet = ["12.0.3.0/24", "12.0.4.0/24", "12.0.5.0/24", "12.0.6.0/24"]
availability_zones  = ["us-east-1a", "us-east-1b"]

#security group
frontend_alb_sg_name         = "frontend-alb-sg"
django_alb_sg_name           = "django-alb-sg"
flask_alb_sg_name            = "flask-alb-sg"
security_group_cidr          = "0.0.0.0/0"
frontend_service_ecs_sg_name = "frontend-service-sg"
django_service_ecs_sg_name   = "django-service-sg"
flask_service_ecs_sg_name    = "flask-service-sg"
django_db_sg_name            = "django-db-sg"
flask_db_sg_name             = "flask-db-sg"
cluster_name                 = "micro-service-cluster"

#route53
domain_name       = "seyram.site"
alternative_names = ["www.seyram.site"]

#RDS
django_secret     = "my-django-db-secret-us-east-1"
flask_secret      = "my-flask-db-secret-us-east-1"
db_instance_class = "db.t3.micro"
storage_type      = "gp2"


# EC2 VARIABLES
ec2_sg_name         = "grafana-prometheus-sg"