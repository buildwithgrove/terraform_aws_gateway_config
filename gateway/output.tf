output "region" {
  value = "${var.region}"
}

output "vpc" {
  value = aws_vpc.gateway_vpc
}

output "vpc_cidr_block" {
  value = aws_vpc.gateway_vpc.cidr_block
}

output "public_subnet_1" {
  value = aws_subnet.gateway_public_sn_01
}

output "public_subnet_2" {
  value = aws_subnet.gateway_public_sn_02
}

output "public_subnet_3" {
  value = aws_subnet.gateway_public_sn_03
}

output "public_subnet_CIDR_1" {
  value = aws_subnet.gateway_public_sn_01.cidr_block
}

output "public_subnet_CIDR_2" {
  value = aws_subnet.gateway_public_sn_02.cidr_block
}

output "public_subnet_CIDR_3" {
  value = aws_subnet.gateway_public_sn_03.cidr_block
}

output "alg_sg"{
  value = aws_security_group.alb_sg.name
}

output "ecs_sg" {
  value = aws_security_group.ecs_sg.name
}

output "redis_sg" {
  value = aws_security_group.redis_sg.name
  
}

output "ecr_repo_url" {
  value = aws_ecr_repository.gateway.repository_url
  
}

output "ecs_cluster" {
  value = aws_ecs_cluster.gateway.name
}

output "cloudwatch_log_group_name" {
  value = aws_cloudwatch_log_group.gateway.name
}

output "redis_endpoint" {
  value = aws_elasticache_replication_group.redis.primary_endpoint_address
}

output "redis_arn" {
  value = aws_elasticache_replication_group.redis.arn
}