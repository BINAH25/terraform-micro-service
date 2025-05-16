terraform {
  backend "s3" {
    bucket       = "micro-service-flask-django-react"
    key          = "terraform.tfstate"
    region       = "us-east-2"
    encrypt      = true
    use_lockfile = true
  }
}