module "vpc" {
  source                  = "../modules/vpc"
  vpc_name                = var.vpc_name
  vpc_cidr                = var.vpc_cidr
  cidr_public_subnet      = var.cidr_public_subnet
  cidr_private_subnet     = var.cidr_private_subnet
  availability_zones      = var.availability_zones
  map_public_ip_on_launch = var.map_public_ip_on_launch
}

module "security_group" {
  vpc_id                       = module.vpc.micro_service_project_vpc
  source                       = "../modules/security_groups"
  frontend_alb_sg_name         = var.frontend_alb_sg_name
  security_group_cidr          = var.security_group_cidr
  frontend_service_ecs_sg_name = var.frontend_service_ecs_sg_name
  django_db_sg_name            = var.django_db_sg_name
  django_alb_sg_name           = var.django_alb_sg_name
  django_service_ecs_sg_name   = var.django_service_ecs_sg_name
  flask_alb_sg_name            = var.flask_alb_sg_name
  flask_db_sg_name             = var.flask_db_sg_name
  flask_service_ecs_sg_name    = var.flask_service_ecs_sg_name
  ec2_sg_name                  = var.ec2_sg_name
}

# ecr repos creation
module "ecr_repos" {
  source   = "../modules/ecr"
  for_each = toset(var.ecr_repositories)
  name     = each.key
  tags = {
    Project = "Microservice"
    Env     = "Dev"
  }
}

# create ecs cluster
module "ecs_cluster" {
  source       = "../modules/ecs-cluster"
  cluster_name = var.cluster_name
}


# Secret manager
module "django_secret" {
  source = "../modules/secret_manager"
  secret_name = var.django_secret
}

module "flask_secret" {
  source = "../modules/secret_manager"
  secret_name = var.flask_secret
}


module "django_db_replica" {
  source = "../modules/rds_replica"

  source_db_arn     = data.terraform_remote_state.primary.outputs.postgres_db_instance_arn
  db_identifier     = "postgres-db"
  db_instance_class = var.db_instance_class
  db_security_group = module.security_group.django_db_sg_name
  private_subnets   = slice(module.vpc.micro_service_project_private_subnets, 2, 4)
  db_subnet_name    = "micro-service-project-django-db-subnet-group"
  db_name           = module.django_secret.db_name
  db_password       = module.django_secret.db_password
  db_username       = module.django_secret.db_username
  secret_id = module.django_secret.secret_id
  db_port = module.django_secret.db_port
  region = var.region
}


module "flask_db_replica" {
  source = "../modules/rds_replica"

  source_db_arn     = data.terraform_remote_state.primary.outputs.mysql_db_instance_arn
  db_identifier     = "mysql-db"
  db_instance_class = var.db_instance_class
  db_security_group = module.security_group.flask_db_sg_name
  private_subnets   = slice(module.vpc.micro_service_project_private_subnets, 2, 4)
  db_subnet_name    = "micro-service-project-flask-db-subnet-group"
  db_name           = module.flask_secret.db_name
  db_password       = module.flask_secret.db_password
  db_username       = module.flask_secret.db_username
  secret_id = module.flask_secret.secret_id
  db_port = module.flask_secret.db_port
  region = var.region
}

# Route 53
module "route53_recovery" {
  source = "../modules/route53"

  domain_name         = var.domain_name
  alb_dns_name        = module.frontend_alb.alb_dns_name
  alb_zone_id         = module.frontend_alb.alb_zone_id
  failover_role       = "SECONDARY"
  create_health_check = true
  health_check_fqdn   = module.frontend_alb.alb_dns_name
  create_www          = false
}


module "djando_domain" {
  source = "../modules/subdomain"
  domain_name = var.domain_name
  subdomain = "django.seyram.site"
  alb_zone_id = module.django_alb.alb_zone_id
  alb_dns_name = module.django_alb.alb_dns_name
  create_health_check = true
  failover_role       = "SECONDARY"
  health_check_fqdn   = module.django_alb.alb_dns_name
}

module "flask_domain" {
  source = "../modules/subdomain"
  domain_name = var.domain_name
  subdomain = "flask.seyram.site"
  alb_zone_id = module.flask_alb.alb_zone_id
  alb_dns_name = module.flask_alb.alb_dns_name
  create_health_check = true
  failover_role       = "SECONDARY"
  health_check_fqdn   = module.flask_alb.alb_dns_name
}


# create load balancer for the services
module "frontend_alb" {
  source            = "../modules/alb"
  name              = "my-frontend-alb"
  security_groups   = [module.security_group.frontend_alb_sg_name]
  subnets           = module.vpc.micro_service_project_public_subnets
  vpc_id            = module.vpc.micro_service_project_vpc
  target_group_name = "my-frontend-tg"
  health_check_path = "/"
  acm_cert_arn      = module.acm_recovery_main.acm_cert_arn
}

# Load balancer
module "django_alb" {
  source            = "../modules/alb"
  name              = "my-django-alb"
  security_groups   = [module.security_group.djando_alb_sg_name]
  subnets           = module.vpc.micro_service_project_public_subnets
  vpc_id            = module.vpc.micro_service_project_vpc
  target_group_name = "my-django-tg"
  target_group_port = 8000
  health_check_path = "/api/products"
  acm_cert_arn      = module.acm_django.acm_cert_arn
}

module "flask_alb" {
  source            = "../modules/alb"
  name              = "my-flask-alb"
  security_groups   = [module.security_group.flask_alb_sg_name]
  subnets           = module.vpc.micro_service_project_public_subnets
  vpc_id            = module.vpc.micro_service_project_vpc
  target_group_name = "my-flask-tg"
  target_group_port = 5000
  health_check_path = "/ready"
  acm_cert_arn      = module.acm_flask.acm_cert_arn
}

# certificate
module "acm_recovery_main" {
  source = "../modules/acm_recovery"

  domain_name        = var.domain_name
  alternative_names  = var.alternative_names
}

module "acm_django" {
  source = "../modules/acm_recovery"

  domain_name       = "django.seyram.site"
  alternative_names = []
}

module "acm_flask" {
  source = "../modules/acm_recovery"
  domain_name       = "flask.seyram.site"
  alternative_names = []
}


# create ecs services 
module "frontend" {
  source               = "../modules/ecs-service"
  name                 = "frontend-recovery"
  family               = "service-one-task"
  cpu                  = "256"
  memory               = "512"
  container_name       = "frontend"
  container_image      = "${module.ecr_repos["frontend-service"].repository_url}:latest"
  container_port       = 80
  cluster_id           = module.ecs_cluster.cluster_id
  subnets              = module.vpc.micro_service_project_public_subnets
  security_groups      = [module.security_group.frontend_service_sg_name]
  desired_count        = 0
  enable_load_balancer = true
  secret_name = ""
  aws_region           = var.region
  target_group_arn     = module.frontend_alb.target_group_arn
}



module "django_service" {
  source               = "../modules/ecs-service"
  name                 = "django-recovery"
  family               = "admin-service-task"
  cpu                  = "256"
  memory               = "512"
  container_name       = "django"
  container_image      = "${module.ecr_repos["admin-service"].repository_url}:latest"
  container_port       = 8000
  cluster_id           = module.ecs_cluster.cluster_id
  subnets              = slice(module.vpc.micro_service_project_private_subnets, 0, 2)
  security_groups      = [module.security_group.django_service_sg_name]
  desired_count        = 0
  enable_load_balancer = true
  aws_region           = var.region
  secret_name = var.django_secret
  target_group_arn     = module.django_alb.target_group_arn
  depends_on = [ module.django_db_replica ]
}



module "django_queue" {
  source               = "../modules/ecs-service"
  name                 = "django-queue-recovery"
  family               = "admin-queue-service-task"
  cpu                  = "256"
  memory               = "512"
  container_name       = "django-queue"
  container_image      = "${module.ecr_repos["admin-service-queue"].repository_url}:latest"
  cluster_id           = module.ecs_cluster.cluster_id
  subnets              = slice(module.vpc.micro_service_project_private_subnets, 0, 2)
  security_groups      = [module.security_group.django_service_sg_name]
  desired_count        = 0
  enable_load_balancer = false
  secret_name = var.django_secret
  aws_region           = var.region
  target_group_arn     = module.django_alb.target_group_arn
  depends_on = [ module.django_service ]
}

module "flask_service" {
  source               = "../modules/ecs-service"
  name                 = "flask-recovery"
  family               = "user-service-task"
  cpu                  = "256"
  memory               = "512"
  container_name       = "flask"
  container_image      = "${module.ecr_repos["user-service"].repository_url}:latest"
  container_port       = 5000
  cluster_id           = module.ecs_cluster.cluster_id
  subnets              = slice(module.vpc.micro_service_project_private_subnets, 0, 2)
  security_groups      = [module.security_group.flask_service_sg_name]
  desired_count        = 0
  enable_load_balancer = true
  aws_region           = var.region
  secret_name = var.flask_secret
  target_group_arn     = module.flask_alb.target_group_arn
  depends_on = [ module.flask_db_replica ]
}


module "flask_queue" {
  source               = "../modules/ecs-service"
  name                 = "flask-queue-recovery"
  family               = "user-queue-service-task"
  cpu                  = "256"
  memory               = "512"
  container_name       = "flask-queue"
  container_image      = "${module.ecr_repos["user-service-queue"].repository_url}:latest"
  cluster_id           = module.ecs_cluster.cluster_id
  subnets              = slice(module.vpc.micro_service_project_private_subnets, 0, 2)
  security_groups      = [module.security_group.flask_service_sg_name]
  desired_count        = 0
  enable_load_balancer = false
  aws_region           = var.region
  secret_name = var.flask_secret
  target_group_arn     = module.flask_alb.target_group_arn
  depends_on = [ module.flask_service ]
}


module "monitoring_primary" {
  source = "../modules/monitoring"
  health_check_id = data.terraform_remote_state.primary.outputs.health_check_id
}


module "lambda_failover" {
  source = "../modules/lambda"
  sns_topic_arn = module.monitoring_primary.sns_topic_arn
  lambda_file     = "../scripts/lambda.zip"         
  lambda_hash     = filebase64sha256("../scripts/lambda.zip")
}
