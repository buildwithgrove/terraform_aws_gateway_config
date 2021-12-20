output "ecr_repository_url" {
  description = "URL of the repository created"
  value       = module.gateway.repository_url
}

output "redis_configuration_endpoint_address" {
    description = "The address of the replication group configuration endpoint when cluster mode is enabled."
    value = module.gateway.redis_configuration_endpoint_address
}