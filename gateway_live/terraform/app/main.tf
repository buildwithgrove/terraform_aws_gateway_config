provider "aws" {
  region = local.region
  default_tags {
      tags = {
          Environment = local.environment
          Project     = "Gateway"
          Automation  = "true"
          Owner       = "DevOps team"
    }  
  }
}

locals {
  name        = "gateway"
  environment = "terraform"
  region      = "ap-northeast-2"
  alb_tg_name    = format("%s-%s", local.name, local.environment)
  vpc_name      = format("%s-%s", local.name, local.environment)
  ecs_sg_name = format("%s-%s-%s", local.name, "ecs", local.environment) 
  subnets    = tolist(data.aws_subnet_ids.gateway_subnets_ids.ids)
}

data "aws_lb_target_group" "gateway_tg" {
  name = local.alb_tg_name
}
data "aws_vpc" "gateway_vpc" {
  filter {
    name = "tag:Name"
    values = [local.vpc_name]
  }
}

data "aws_security_group" "ecs_sg" {
  name = local.ecs_sg_name
}

data "aws_subnet_ids" "gateway_subnets_ids" {
  vpc_id = data.aws_vpc.gateway_vpc.id
}

data "aws_iam_role" "ecs_autoscale_role" {
  name = "AWSServiceRoleForApplicationAutoScaling_ECSService"
}

data "aws_iam_role" "ecs_task_execution_role" {
  name = "ecsTaskExecutionRole"
}

data "aws_launch_template" "gateway_template" {
  name = "${local.name}-${local.environment}"
}

module "asg" {
    source = "../../../gateway_modules/autoscalling/"

    name        = local.name
    environment = local.environment

    min_size                = 1
    max_size                = 50
    # desired_capacity        = 10
    target_group_arns       = [data.aws_lb_target_group.gateway_tg.arn]
    launch_template         = data.aws_launch_template.gateway_template.name
    launch_template_version = data.aws_launch_template.gateway_template.latest_version
    vpc_zone_identifier     = local.subnets
}



module "ecs" {
    source = "../../../../modules/services/app"

    name        = local.name
    environment = local.environment
    
    # ---------- ecs cluster ----------
    capacity_providers = ["FARGATE", "FARGATE_SPOT"]
    default_capacity_provider_strategy = [{
        capacity_provider = "FARGATE"
        weight            = "1"
        base              = "1" }]
    
    kms_key_id         = null
    logging            = "NONE"

    setting_name       = "containerInsights"
    container_insights = true    

    # ---------- ecs task definition ----------
    task_role_arn            = "${data.aws_iam_role.ecs_task_execution_role.arn}"
    execution_role_arn       = "${data.aws_iam_role.ecs_task_execution_role.arn}"
    cpu                      = 1024
    memory                   = 4096
    network_mode             = "awsvpc"
    requires_compatibilities = ["FARGATE"]

    # ---------- ecs service  ----------
    launch_type 						            = "FARGATE"
    desired_count   					          = 3
    platform_version 					          = "LATEST"
    scheduling_strategy 			        	= "REPLICA"
    deployment_minimum_healthy_percent 	= 100
    deployment_maximum_percent			    = 200	
    health_check_grace_period_seconds	  = 90
    
    load_balancer = [ {
        target_group_arn = "${data.aws_lb_target_group.gateway_tg.arn}"
        container_port   = 3000
        container_name   = "gateway"
    }]
    subnets 						                = local.subnets
    security_groups 				            = [data.aws_security_group.ecs_sg.id]
    assign_public_ip 				            = true
    deployment_controller_type 	        = "ECS"
    deployment_circuit_breaker          = true 
    deployment_circuit_breaker_rollback = true
}


module "appautoscaling" {
    source = "../../../../modules/services/autoscalling"

    name        = local.name
    environment = local.environment

    # ---------- application autoscaling target ----------
    service_namespace   = "ecs"
    resource_id         = format("service/%s/%s", module.ecs.cluster_name, module.ecs.service_name)
    scalable_dimension  = "ecs:service:DesiredCount"
    role_arn            = data.aws_iam_role.ecs_autoscale_role.arn
    min_capacity        = 3
    max_capacity        = 50 

    # ---------- application autoscaling policy ----------
    policy_name            = "${local.name}-${local.environment}-TargetTrackingScalling"
    policy_type            = "TargetTrackingScaling"
    predefined_metric_type = "ECSServiceAverageCPUUtilization"
    target_value       = 10
    scale_in_cooldown  = 300
    scale_out_cooldown = 300
    disable_scale_in   = false 
}

module "metric_alarms_high_cpu" {
  source = "../../../../modules/services/cloudwatch"

  create_metric_alarm = true
  name                = local.name
  environment         = local.environment

  alarm_name          = "high-cpu"
  alarm_description   = "gateway ecs task high cpu utilization"
  actions_enabled     = true

  alarm_actions       = [module.appautoscaling.policy_arn]

  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "3"
  threshold           = "10"
  unit                = "Percent"

  datapoints_to_alarm = "3"
  treat_missing_data  = "missing"
  
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = "60"
  statistic           = "Average"
  dimensions = {
    ClusterName = module.ecs.cluster_name
    ServiceName = module.ecs.service_name
  }
}

module "metric_alarms_low_cpu" {
  source = "../../../../modules/services/cloudwatch"

  create_metric_alarm = true
  name                = local.name
  environment         = local.environment

  alarm_name          = "low-cpu"
  alarm_description   = "low cpu utilization on ecs gateway service"
  actions_enabled     = true

  alarm_actions       = [module.appautoscaling.policy_arn]

  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "15"
  threshold           = "9"
  unit                = "Percent"

  datapoints_to_alarm = "15"
  treat_missing_data  = "missing"
  
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = "60"
  statistic           = "Average"
  dimensions = {
    ClusterName = module.ecs.cluster_name
    ServiceName = module.ecs.service_name
  }
}


