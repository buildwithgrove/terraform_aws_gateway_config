locals {
  name        = var.name
  environment = var.environment
  region      = var.region
  tags = {
    Environment = local.environment
    Project     = "Gateway"
    Automation  = "true"
    Owner       = "DevOps team"
    }  
  public_subnets  = var.public_subnets

  ingress_with_cidr_blocks = var.ingress_with_cidr_blocks

  instance_type = var.instance_type

  domain_name = var.domain_name
}