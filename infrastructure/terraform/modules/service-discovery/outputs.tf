output "namespace_id" {
  description = "ID of the Cloud Map private DNS namespace"
  value       = aws_service_discovery_private_dns_namespace.main.id
}

output "namespace_arn" {
  description = "ARN of the Cloud Map private DNS namespace"
  value       = aws_service_discovery_private_dns_namespace.main.arn
}

output "namespace_name" {
  description = "Name of the Cloud Map private DNS namespace"
  value       = aws_service_discovery_private_dns_namespace.main.name
}

output "backend_service_id" {
  description = "ID of the backend service discovery service"
  value       = aws_service_discovery_service.backend.id
}

output "backend_service_arn" {
  description = "ARN of the backend service discovery service"
  value       = aws_service_discovery_service.backend.arn
}

output "frontend_service_id" {
  description = "ID of the frontend service discovery service"
  value       = aws_service_discovery_service.frontend.id
}

output "frontend_service_arn" {
  description = "ARN of the frontend service discovery service"
  value       = aws_service_discovery_service.frontend.arn
}
