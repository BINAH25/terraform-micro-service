data "terraform_remote_state" "primary" {
  backend = "s3"
  config = {
    bucket = "micro-service-flask-django-react"
    key    = "terraform.tfstate"
    region = "us-east-2"
  }
}


terraform {
  backend "s3" {
    bucket       = "micro-service-flask-django-react-recovery"
    key          = "terraform.tfstate"
    region       = "us-east-1"
    encrypt      = true
    use_lockfile = true
  }
}