variable "source_db_arn" {}
variable "db_identifier" {}
variable "db_instance_class" {}
variable "db_subnet_name" {}
variable "private_subnets" {
  type = list(string)
}
variable "db_security_group" {}



variable "db_name" {
  type = string
  description = "name of database"
}
variable "db_password" {
  type = string
  description = "password for database"
}

variable "db_username" {
  type = string
  description = "username for database"
}

variable "secret_id" {
  type        = string
  description = "The ID of the secret to update after DB is created"
}

variable "db_port" {}

variable "region" {
  type        = string
  description = "AWS region"
}
