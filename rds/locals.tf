locals {
  name        = "rds"
  environment = var.environment
  region      = var.region
  tags = {
    Project    = "Gateway"
    Automation = "true"
    Owner      = "DevOps team"
  }
  ingress_with_cidr_blocks = var.ingress_with_cidr_blocks
}
