terraform {
  backend "s3" {
    bucket       = "micro-service-flask-django"
    key          = "terraform.tfstate"
    region       = "us-west-2"
    encrypt      = true
    use_lockfile = true
  }
}