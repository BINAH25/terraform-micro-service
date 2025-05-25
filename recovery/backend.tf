terraform {
  backend "s3" {
    bucket       = "micro-service-flask-django-react-recovery"
    key          = "terraform.tfstate"
    region       = "us-east-1"
    encrypt      = true
    use_lockfile = true
  }
}