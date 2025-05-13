############## PRIMARY REGION SETUP ######################################
module "vpc" {
  source = "../modules/vpc"

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
}

module "route53_main" {
  source = "../modules/route53"

  domain_name         = var.domain_name
  alb_dns_name        = module.frontend_alb.alb_dns_name
  alb_zone_id         = module.frontend_alb.alb_zone_id
  failover_role       = "PRIMARY"
  create_health_check = true
  health_check_fqdn   = module.frontend_alb.alb_dns_name
}

module "acm_primary" {
  source = "../modules/acm"

  domain_name       = var.domain_name
  alternative_names = var.alternative_names
  hosted_zone_id    = module.route53_main.hosted_zone_id
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


module "ecs_cluster" {
  source       = "../modules/ecs-cluster"
  cluster_name = var.cluster_name
}

module "frontend_alb" {
  source            = "../modules/alb"
  name              = "my-frontend-alb"
  security_groups   = [module.security_group.frontend_alb_sg_name]
  subnets           = module.vpc.micro_service_project_public_subnets
  vpc_id            = module.vpc.micro_service_project_vpc
  target_group_name = "my-frontend-tg"
  health_check_path = "/"
  acm_cert_arn      = module.acm_primary.acm_cert_arn
}

module "frontend" {
  source               = "../modules/ecs-service"
  name                 = "frontend"
  family               = "service-one-task"
  cpu                  = "256"
  memory               = "512"
  container_name       = "frontend"
  container_image      = "${module.ecr_repos["frontend-service"].repository_url}:latest"
  container_port       = 80
  cluster_id           = module.ecs_cluster.cluster_id
  subnets              = module.vpc.micro_service_project_public_subnets
  security_groups      = [module.security_group.frontend_service_sg_name]
  desired_count        = 1
  enable_load_balancer = true
  aws_region           = var.region
  target_group_arn     = module.frontend_alb.target_group_arn
}


