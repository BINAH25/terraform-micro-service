output "vpc_id" {
  value = module.vpc.micro_service_project_vpc

}

output "ecr_urls" {
  value = {
    for name, mod in module.ecr_repos : name => mod.repository_url
  }
}
