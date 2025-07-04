variable "name" { type = string }
variable "cluster_id" { type = string }

variable "family" { type = string }
variable "cpu" { type = string }
variable "memory" { type = string }

variable "container_name" { type = string }
variable "container_image" { type = string }
variable "container_port" {
  description = "Port exposed by the container"
  type        = number
  default     = null
}

variable "subnets" { type = list(string) }
variable "security_groups" { type = list(string) }

variable "desired_count" { type = number }

variable "environment" {
  type    = list(map(string))
  default = []
}

variable "enable_load_balancer" {
  type    = bool
  default = false
}

variable "target_group_arn" {
  type    = string
  default = ""
}

variable "aws_region" {
  description = "AWS region for CloudWatch logging"
  type        = string
}

variable "log_group_name" {
  description = "CloudWatch Log Group name"
  type        = string
  default     = ""
}

# variable "loki_url" {
#   description = "url for loki"
#   type        = string
# }
variable "secret_name" {
  type        = string
  description = "The name of the existing secret"
}
variable "jeager_port" {
  
}
variable "jeager_url" {
  type = string
}
variable "rabbit_mq_url" {
  type = string
}
variable "assign_public_ip" {
  type = bool
  default = false
}