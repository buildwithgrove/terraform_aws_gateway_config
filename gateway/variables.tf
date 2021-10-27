variable "aws_access_key_id" {}

variable "aws_secret_access_key" {}

variable "region" {}

variable "environment" {
  description = "dev, test or prod env"
}
variable "vpc_name" {}

variable "vpc_cidr_block" {}

variable "public_subnet_name_1" {}

variable "public_subnet_name_2" {}

variable "public_subnet_name_3" {}

variable "public_subnet_CIDR_1" {}

variable "public_subnet_CIDR_2" {}

variable "public_subnet_CIDR_3" {}

variable "alb_sg_name" {}

variable "ecs_sg_name" {}

variable "redis_sg_name" {}

variable "ecr_repo" {}

variable "ecs_cluster" {}

variable "elasticache_replication_group_id" {}

variable "application_load_balancer_name" {}

variable "target_group_name" {}

variable "ssl_domain" {}

variable "task_definition_familly" {}

variable "fargate_cpu" {}
variable "fargate_memory" {  
}

variable "image_url" {}

variable "log_group" {}

variable "ecs-service" {}

