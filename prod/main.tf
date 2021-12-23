provider "aws" {
  region     = local.region
  access_key = var.aws_access_key_id
  secret_key = var.aws_secret_access_key
  default_tags {
    tags = local.tags
  }
}

module "alb_sg" {

  source  = "app.terraform.io/pokt-foundation/gateway/aws//modules/security_groups"
  version = "1.0.0" 

  #----- security group --------
  name        = format("%s-%s-%s", local.name, "alb", local.environment)
  vpc_id      = module.gateway.vpc_id
  description = format("%s %s security group", local.name, "alb")
  
  timeout_sg_create = "5m"
  timeout_sg_delete = "7m"

  #----- rules --------
  ingress_with_cidr_blocks = [{
    rule        = "alb-https"
    cidr_blocks = "0.0.0.0/0"
  }]

  egress_with_cidr_blocks = [ {
    rule = "all-all"
    cidr_blocks = "0.0.0.0/0"

  } ]
}

module "ecs_sg" {

  source  = "app.terraform.io/pokt-foundation/gateway/aws//modules/security_groups"
  version = "1.0.0" 

  #----- security group --------
  name        = format("%s-%s-%s", local.name, "ecs", local.environment)
  vpc_id      = module.gateway.vpc_id
  description = format("%s %s security group", local.name, "ecs")

  timeout_sg_create = "5m"
  timeout_sg_delete = "7m"
  
  #----- rules --------
  ingress_with_cidr_blocks = local.ingress_with_cidr_blocks == [] ? null : local.ingress_with_cidr_blocks

  ingress_with_source_security_group_id = [ {
    rule = "ecs-tcp"
    source_security_group_id = module.alb_sg.id
  } ]

  egress_with_cidr_blocks = [ {
    rule = "all-all"
    cidr_blocks = "0.0.0.0/0"
  } ]
  
}

module "redis_sg" {
  
  source  = "app.terraform.io/pokt-foundation/gateway/aws//modules/security_groups"
  version = "1.0.0"  

  #----- security group --------
  name        = format("%s-%s-%s", local.name, "redis", local.environment)
  vpc_id      = module.gateway.vpc_id
  description = format("%s %s security group", local.name, "redis")

  timeout_sg_create = "5m"
  timeout_sg_delete = "7m"
  
  #----- rules --------
  ingress_with_source_security_group_id = [ {
    rule = "redis-tcp"
    source_security_group_id = module.ecs_sg.id
  } ]

  egress_with_cidr_blocks = [ {
    rule = "all-all"
    cidr_blocks = "0.0.0.0/0"
  } ]
  
}

module "gateway" {
  source  = "app.terraform.io/pokt-foundation/gateway/aws"
  version = "1.0.0" 

  name    = "${local.name}-${local.environment}"
  vpc_id  = module.gateway.vpc_id

  # ---------- ecr -----------
  repo_name            = "${local.name}-${local.environment}"
  image_tag_mutability = "MUTABLE"
  scan_images_on_push  = false
  encryption_type      = "AES256"
  repo_delete_timeout  = "20m"  

  #----- VPC --------
  cidr        = var.vpc_cidr
  enable_ipv6 = false

  #----- public route --------
  route_table_id         = module.gateway.public_route_table_id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = module.gateway.igw_id
  timeout_create_route   = "5m"
  timeout_update_route   = "2m"
  timeout_delete_route   = "2m"

  #----- subnets --------
  subnet_count    = length(local.public_subnets)
  azs             = ["${local.region}a", "${local.region}b", "${local.region}c"]
  public_subnets  = local.public_subnets

  timeout_create_subnet = "10m"
  timeout_delete_subnet = "5m"

  #----- route table association --------
  route_table_association_count  = length(local.public_subnets)

  association_route_table_id     = module.gateway.public_route_table_id

  association_subnet_id          = module.gateway.public_subnet_ids 

  # ---------- elasticachesubnet group ----------
  redis_sb_group_description   = "provide redis with all the subnets associated with it"
  subnet_ids                   = module.gateway.public_subnet_ids

  # ---------- elasticache replication group ----------
  engine                        = "redis"
  engine_version                = "6.x"
  port                          = 6379
  parameter_group_name          = "default.redis6.x.cluster.on"
  node_type                     = var.redis_node_type
  multi_az_enabled              = true 
  automatic_failover_enabled    = true
  availability_zones            = ["${local.region}a", "${local.region}b", "${local.region}c"]
  replication_group_description = "gateway redis elasticache"
  security_group_ids            = [module.redis_sg.id]
  at_rest_encryption_enabled    = true 
  transit_encryption_enabled    = false
  maintenance_window            = "mon:18:00-mon:19:00"
  apply_immediately             = true
  
  # cluster mode enabled 
  cluster_mode_enabled                 = true
  cluster_mode_num_node_groups         = 1 # shards
  cluster_mode_replicas_per_node_group = 2

  # ---------- ssl certificate ----------
  domain_name               = local.domain_name
  subject_alternative_names = [
        "*.api.s0.b.hmny.io",
        "*.api.s0.stn.hmny.io",
        "*.api.s0.t.hmny.io",
        "*.api.s1.b.hmny.io",
        "*.api.s1.stn.hmny.io",
        "*.api.s1.t.hmny.io",
        "*.api.s2.b.hmny.io",
        "*.api.s2.stn.hmny.io",
        "*.api.s2.t.hmny.io",
        "*.api.s3.b.hmny.io",
        "*.api.s3.stn.hmny.io",
        "*.api.s3.t.hmny.io",
        "*.b.hmny.io",
        "*.harmony.one",
        "*.hmny.io",
        "*.s0.b.hmny.io",
        "*.s0.stn.hmny.io",
        "*.s0.t.hmny.io",
        "*.s1.b.hmny.io",
        "*.s1.stn.hmny.io",
        "*.s1.t.hmny.io",
        "*.s2.b.hmny.io",
        "*.s2.stn.hmny.io",
        "*.s2.t.hmny.io",
        "*.s3.b.hmny.io",
        "*.s3.stn.hmny.io",
        "*.s3.t.hmny.io",
        "*.stn.hmny.io",
        "*.t.hmny.io",
    ]
  validation_method                           = "DNS"
  certificate_transparency_logging_preference = true  
  
  # ---------- ALB ----------

  load_balancer_type         = "application"
  internal                   = false
  security_groups            = [module.alb_sg.id] 
  subnets                    = module.gateway.public_subnet_ids
  enable_http2               = true
  ip_address_type            = "ipv4"
  drop_invalid_header_fields = true
  desync_mitigation_mode     = "defensive"

  load_balancer_create_timeout = "10m"
  load_balancer_update_timeout = "10m"
  load_balancer_delete_timeout = "10m"

  target_groups = [
      {
        name                 = format("%s-%s", local.name, local.environment)
        port                 = 3000
        protocol             = "HTTP"
        protocol_version     = "HTTP1"
        target_type          = "instance"
        deregistration_delay           = 120
        load_balancing_algorithm_type  = "least_outstanding_requests"

        health_check = {
          enabled             = true
          interval            = 30
          path                = "/"
          port                = "traffic-port"
          healthy_threshold   = 5
          unhealthy_threshold = 2
          timeout             = 5
          protocol            = "HTTP"
          matcher             = "200"
        }
      }
  ]

  https_listeners = [
    # Forward action is default, either when defined or undefined 
    {
      load_balancer_arn  = module.gateway.alb_arn[0]
      port               = 443
      protocol           = "HTTPS"
      certificate_arn    = module.gateway.ssl_arn[0]
      ssl_policy         = "ELBSecurityPolicy-2016-08"
      action_type        = "forward"
      target_group_index = 0
    }
  ]

  # ----------- ssh key ----------
  ssh_key_name   = "gateway-infra"
  ssh_public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCbkaq3ikeIw0Wi5PHsQ1AxDpzMq6IPxRLubz/FSkFEfPWj73aM6gwaqwNUVH5k5C2HESO3VDEyjhsb6/fy1IXXTEhhfB8OYL+FXNvN+EgwXHdTWvT86DBzWxtWyL/ZB1YpnxXcXmoR24FgGewHNyj8XS4VVG9dvwNfJ7Dg6QTeB+nTT9v6vqaCiklbmsl0yPlyu1uupkj5D0zmaBAa6EPvhLHfUsWdSt33D2MQb5XRXmbfnEhQnBFqcQsV+5sWVVK2BAln3wKnKiiaU+fbP2hoLc8MGCGT2IvK7RH7o4jbUaRTbMJUrvLzvnazKB/X+q/Rb+ixGIqsndmBQd0LYzWd"

  # ----------- launch template ----------

  description = "gateway ecs ec2 launch template"
  update_default_version  = true  
  disable_api_termination = false

  image_id      = data.aws_ami.amazon_linux.id
  instance_type = local.instance_type
  ebs_optimized = true

  user_data_base64 = base64encode(
  <<EOF
  #!/bin/bash
  echo 'ECS_CLUSTER=${local.name}-${local.environment}' >> /etc/ecs/ecs.config
  echo 'ECS_DISABLE_PRIVILEGED=true' >> /etc/ecs/ecs.config
  echo 'ECS_ENABLE_CONTAINER_METADATA=true' >> /etc/ecs/ecs.config
  EOF 
  )

  instance_initiated_shutdown_behavior = "stop"
  iam_instance_profile_name = data.aws_iam_instance_profile.gateway.name

  enable_monitoring           = true
  associate_public_ip_address = true
  block_device_mappings = [
    {
      # Root volume
      device_name = "/dev/xvda"
      no_device   = 0
      virtual_name =  null
      ebs = {
        delete_on_termination = true
        encrypted             = false
        volume_size           = 30
        volume_type           = "gp3"
        iops                  = 5000
        kms_key_id            = null
        snapshot_id           = null
        throughput            = 250
      }
    }
  ]

  metadata_options = {
    http_endpoint               = "enabled"
    http_tokens                 = "optional"
    http_put_response_hop_limit = 1
    http_protocol_ipv6          = "disabled"
  }

  network_interfaces = [
    {
      delete_on_termination       = true
      description                 = "eth0"
      device_index                = 0
      security_groups             = [module.ecs_sg.id]
      associate_public_ip_address = true
      # interface_type              = "Network interface"
    },
  ]
  
  tag_specifications = [
    {
      resource_type = "instance"
      tags          = merge(
        {
          Name = "${local.name}-${local.environment}"
        }, 
        local.tags,
      )
    },
    {
      resource_type = "volume"
      tags          = merge(
        {
          Name = "${local.name}-${local.environment}"
        }, 
        local.tags,
      )
    }
  ]

  # ----------  autoscaling group ----------
  min_size                = 0
  max_size                = 100
  target_group_arns       = module.gateway.target_group_arns
  launch_template_id      = module.gateway.launch_template_id
  launch_template_version = module.gateway.launch_template_latest_version
  vpc_zone_identifier     = module.gateway.public_subnet_ids
  service_linked_role_arn = data.aws_iam_role.autoscaling.arn
  termination_policies    = ["OldestLaunchTemplate", "OldestInstance"]
  protect_from_scale_in   = false

  health_check_type         = "EC2" #"ELB"
  health_check_grace_period = 300

  default_cooldown          = 300


  force_delete   = false
  asg_delete_timeout = "20m" 

  instance_refresh = {
    strategy  = "Rolling"
    triggers  = ["tag"]
    preferences = {
      checkpoint_delay       = 600
      checkpoint_percentages = [35, 70, 100]
      instance_warmup        = 300
      min_healthy_percentage = 90
    }
  }
  tags_as_map = {
    Name  = format("%s-%s", local.name, local.environment)
  }  

  # ------------ ecs capacity provider ----------
  auto_scaling_group_arn = module.gateway.autoscaling_group_arn
  managed_scaling_status = "ENABLED"
  managed_scaling_instance_warmup_period = 300
  managed_scaling_target_capacity = 100

  # ---------- ecs cluster ----------
  create_ecs_cluster = true

  capacity_providers = [module.gateway.capacity_provider_name]
  default_capacity_provider_strategy = [{
      capacity_provider = module.gateway.capacity_provider_name
      weight            = "1"
      base              = "1" 
      }]
  
  ecs_cluster_kms_key_id         = null
  logging                        = "NONE"

  setting_name       = "containerInsights"
  container_insights = true    

  # ---------- ecs service  ----------
  create_ecs_service = true
  service_name    = "${local.name}-${local.environment}"
  task_definition = "${data.aws_ecs_task_definition.gateway.family}:${max(data.aws_ecs_task_definition.gateway.revision)}"
  capacity_provider_strategy = [{
    	capacity_provider =  module.gateway.capacity_provider_name
			weight            = "1"
			base              = "1"
  }]
  desired_count                       = 3 
  scheduling_strategy 			        	= "REPLICA"
  deployment_minimum_healthy_percent 	= 100
  deployment_maximum_percent			    = 200	
  health_check_grace_period_seconds	  = 90
  
  load_balancer = [{
      target_group_arn = module.gateway.target_group_arns[0]
      container_port   = 3000
      container_name   = "gateway"
  }]
  deployment_controller_type 	        = "ECS"
  deployment_circuit_breaker          = true 
  deployment_circuit_breaker_rollback = true

  ecs_service_tags = {
    "Name" = "${local.name}-${local.environment}"
  }

  # ---------- application autoscaling target ----------
  create_appautoscaling_target = true

  service_namespace   = "ecs"
  resource_id         = format("service/%s/%s", module.gateway.cluster_name, module.gateway.service_name)
  scalable_dimension  = "ecs:service:DesiredCount"
  role_arn            = data.aws_iam_role.ecs_autoscale_role.arn
  min_capacity        = 3
  max_capacity        = 100

  # ---------- application autoscaling policy ----------
  create_appautoscaling_policy = true

  policy_name            = "${local.name}-${local.environment}-TargetTrackingScalling"
  policy_type            = "TargetTrackingScaling"
  predefined_metric_type = "ECSServiceAverageCPUUtilization"
  target_value       = 20
  scale_in_cooldown  = 300
  scale_out_cooldown = 300
  disable_scale_in   = false 

}

module "accelerator_endpoint" {
  
  source  = "app.terraform.io/pokt-foundation/gateway/aws//modules/accelerator_endpoint_group"
  version = "1.0.0"

  listener_arn = "arn:aws:globalaccelerator::059424750518:accelerator/aa06a2da-9284-4234-9b97-b5db6cf47461/listener/2e78ac20"

  config = {
    endpoint_group_region         = local.region
    health_check_interval_seconds = 30
    health_check_path             = "/"
    health_check_port             = 443
    health_check_protocol         = "TCP"
    threshold_count               = 3
    traffic_dial_percentage       = 0
    endpoint_configuration = [{
      client_ip_preservation_enabled = true
      endpoint_id                    = module.gateway.alb_arn[0]
      weight                         = 0
    }]
  }
  
}