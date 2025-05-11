############## PRIMARY REGION SETUP ######################################
module "vpc" {
    source = "../modules/vpc"

    vpc_name = var.vpc_name
    vpc_cidr = var.vpc_cidr
    cidr_public_subnet = var.cidr_public_subnet
    cidr_private_subnet = var.cidr_private_subnet
    availability_zones = var.availability_zones
    map_public_ip_on_launch = var.map_public_ip_on_launch
}

# ecr repos creation
module "ecr_repos" {
    source = "../modules/ecr"
    for_each   = toset(var.ecr_repositories)
    name = each.key
    tags = {
        Project = "Microservice"
        Env     = "Dev"
    }
}

