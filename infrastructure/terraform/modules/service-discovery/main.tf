# Create a private DNS namespace in Cloud Map
resource "aws_service_discovery_private_dns_namespace" "main" {
  name        = "${var.context.project}-${var.context.environment}.local"
  description = "Private DNS namespace for ${var.context.project} ${var.context.environment} services"
  vpc         = var.vpc_id

  tags = merge(
    var.context.common_tags,
    {
      Name = "${var.context.project}-${var.context.environment}-namespace"
    }
  )
}

# Create a service discovery service for backend
resource "aws_service_discovery_service" "backend" {
  name = "backend"

  dns_config {
    namespace_id = aws_service_discovery_private_dns_namespace.main.id

    dns_records {
      ttl  = 10
      type = "A"
    }

    routing_policy = "MULTIVALUE"
  }

  health_check_custom_config {
    failure_threshold = 1
  }

  tags = merge(
    var.context.common_tags,
    {
      Name = "${var.context.project}-${var.context.environment}-backend-service"
    }
  )
}

# Create a service discovery service for frontend
resource "aws_service_discovery_service" "frontend" {
  name = "frontend"

  dns_config {
    namespace_id = aws_service_discovery_private_dns_namespace.main.id

    dns_records {
      ttl  = 10
      type = "A"
    }

    routing_policy = "MULTIVALUE"
  }

  health_check_custom_config {
    failure_threshold = 1
  }

  tags = merge(
    var.context.common_tags,
    {
      Name = "${var.context.project}-${var.context.environment}-frontend-service"
    }
  )
}
