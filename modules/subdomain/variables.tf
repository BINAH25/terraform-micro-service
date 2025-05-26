variable "domain_name" {
  description = "Main domain name (e.g., example.com)"
  type        = string
}

variable "subdomain" {
  description = "Subdomain name (e.g., api.example.com)"
  type        = string
}

variable "alb_dns_name" {
  description = "DNS name of the ALB"
  type        = string
}

variable "alb_zone_id" {
  description = "Zone ID of the ALB"
  type        = string
}
variable "failover_role" {
  type    = string
  default = "PRIMARY" 
}

variable "create_health_check" {
  type    = bool
  default = true
}

variable "health_check_fqdn" {
  type    = string
  default = ""
}