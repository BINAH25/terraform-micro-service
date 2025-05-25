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
  django_db_sg_name = var.django_db_sg_name
  django_alb_sg_name = var.django_alb_sg_name
  django_service_ecs_sg_name = var.django_service_ecs_sg_name
  flask_alb_sg_name = var.flask_alb_sg_name
  flask_db_sg_name = var.flask_db_sg_name
  flask_service_ecs_sg_name = var.flask_service_ecs_sg_name
  ec2_sg_name = var.ec2_sg_name
}