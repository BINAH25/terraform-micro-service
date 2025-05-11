region              = "us-east-2"
vpc_cidr            = "12.0.0.0/16"
vpc_name            = "micro-service-proj-us-east-vpc"
cidr_public_subnet  = ["12.0.1.0/24", "12.0.2.0/24"]
cidr_private_subnet = [ "12.0.3.0/24", "12.0.4.0/24", "12.0.5.0/24", "12.0.6.0/24"]
availability_zones  = ["us-east-2a", "us-east-2b"]
