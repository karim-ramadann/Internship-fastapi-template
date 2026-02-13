output "compute_environments" {
  description = "Map of compute environments created and their associated attributes"
  value       = module.batch.compute_environments
}

output "job_queues" {
  description = "Map of job queues created and their associated attributes"
  value       = module.batch.job_queues
}

output "job_definitions" {
  description = "Map of job definitions created and their associated attributes"
  value       = module.batch.job_definitions
}

output "scheduling_policies" {
  description = "Map of scheduling policies created and their associated attributes"
  value       = module.batch.scheduling_policies
}

output "instance_iam_role_arn" {
  description = "The Amazon Resource Name (ARN) specifying the instance IAM role"
  value       = module.batch.instance_iam_role_arn
}

output "instance_iam_role_name" {
  description = "The name of the instance IAM role"
  value       = module.batch.instance_iam_role_name
}

output "instance_iam_instance_profile_arn" {
  description = "ARN assigned by AWS to the instance profile"
  value       = module.batch.instance_iam_instance_profile_arn
}

output "service_iam_role_arn" {
  description = "The Amazon Resource Name (ARN) specifying the service IAM role"
  value       = module.batch.service_iam_role_arn
}

output "service_iam_role_name" {
  description = "The name of the service IAM role"
  value       = module.batch.service_iam_role_name
}

output "spot_fleet_iam_role_arn" {
  description = "The Amazon Resource Name (ARN) specifying the spot fleet IAM role"
  value       = module.batch.spot_fleet_iam_role_arn
}

output "spot_fleet_iam_role_name" {
  description = "The name of the spot fleet IAM role"
  value       = module.batch.spot_fleet_iam_role_name
}
