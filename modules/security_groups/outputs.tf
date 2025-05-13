output "frontend_alb_sg_name" {
  value = aws_security_group.frontend_alb_sg.id

}

output "frontend_service_sg_name" {
  value = aws_security_group.frontend_service_sg.id

}