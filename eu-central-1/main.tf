provider "aws" {
  region = local.region
  default_tags {
    tags = local.tags
  }
}

module "ecr" {

  source  = "app.terraform.io/pokt-foundation/gateway/aws//modules/ecr"
  version = "0.0.1"    

  repo_name                = "${local.name}-${local.environment}"
  image_tag_mutability     = "MUTABLE"
  scan_images_on_push      = false
  encryption_type          = "AES256"
}

module "vpc" {

  source = "app.terraform.io/pokt-foundation/gateway/aws//modules/networking/vpc"
  version = "0.0.1" 

  #----- VPC --------
  name    = "${local.name}-${local.environment}"
  cidr        = "10.0.0.0/16"
  enable_ipv6 = false

  
  #----- public route --------
  route_table_id         = module.vpc.public_route_table_id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = module.vpc.igw_id
  timeout_create_route   = "5m"
  timeout_update_route   = "2m"
  timeout_delete_route   = "2m"

  #----- subnets --------
  subnet_count    = length(local.public_subnets)
  vpc_id          = module.vpc.vpc_id
  azs             = ["${local.region}a", "${local.region}b", "${local.region}c"]
  public_subnets  = local.public_subnets

  timeout_create_subnet = "10m"
  timeout_delete_subnet = "5m"

  #----- route table association --------
  route_table_association_count  = length(local.public_subnets)

  association_route_table_id     = module.vpc.public_route_table_id

  association_subnet_id          = module.vpc.public_subnet_ids
}

module "alb_sg" {

  source = "app.terraform.io/pokt-foundation/gateway/aws//modules/networking/security_groups"
  version = "0.0.1" 
  #----- security group --------
  name        = format("%s-%s-%s", local.name, "alb", local.environment)
  vpc_id      = module.vpc.vpc_id
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

  source = "app.terraform.io/pokt-foundation/gateway/aws//modules/networking/security_groups"
  version = "0.0.1" 

  #----- security group --------
  name        = format("%s-%s-%s", local.name, "ecs", local.environment)
  vpc_id      = module.vpc.vpc_id
  description = format("%s %s security group", local.name, "ecs")

  timeout_sg_create = "5m"
  timeout_sg_delete = "7m"
  
  #----- rules --------
  ingress_with_cidr_blocks = [{
    rule = "ssh-tcp"
    cidr_blocks = "176.189.65.240/32"
  }]

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

  source = "app.terraform.io/pokt-foundation/gateway/aws//modules/networking/security_groups"
  version = "0.0.1" 

  #----- security group --------
  name        = format("%s-%s-%s", local.name, "redis", local.environment)
  vpc_id      = module.vpc.vpc_id
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

module "redis" {

    source = "app.terraform.io/pokt-foundation/gateway/aws//modules/data-storage"
    version = "0.0.1" 

    name        = "${local.name}-${local.environment}"

  # ---------- elasticachesubnet group ----------
  redis_sb_group_description   = "provide redis with all the subnets associated with it"
  subnet_ids                   = module.vpc.public_subnet_ids

  # ---------- elasticache replication group ----------
  engine                        = "redis"
  engine_version                = "6.x"
  port                          = 6379
  parameter_group_name          = "default.redis6.x.cluster.on"
  node_type                     = "cache.r6g.xlarge"
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
}

module "ssl_certificate" {

  source = "app.terraform.io/pokt-foundation/gateway/aws//modules/acm"
  version = "0.0.1" 

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

}

module "ssl_dns_validation" {

    source = "app.terraform.io/pokt-foundation/gateway/aws//modules/dns/records"
    version = "0.0.1" 
    
    zone_id        = data.aws_route53_zone.dns_zone.id
    record_name    = module.ssl_certificate.main_domain_validation_options[local.domain_name]["name"]
    type           = module.ssl_certificate.main_domain_validation_options[local.domain_name]["type"]
    records        = [module.ssl_certificate.main_domain_validation_options[local.domain_name]["record"]]
    dns_ttl        = 60
}

module "alb" {

  source = "app.terraform.io/pokt-foundation/gateway/aws//modules/load_balancing"
  version = "0.0.1" 

  # ---------- alb ---------- 
  name                       = "${local.name}-${local.environment}"
  vpc_id                     = module.vpc.vpc_id
  load_balancer_type         = "application"
  internal                   = false
  security_groups            = [module.alb_sg.id] 
  subnets                    = module.vpc.public_subnet_ids
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
      load_balancer_arn  = module.alb.arn[0]
      port               = 443
      protocol           = "HTTPS"
      certificate_arn    = module.ssl_certificate.arn[0]
      ssl_policy         = "ELBSecurityPolicy-2016-08"
      action_type        = "forward"
      target_group_index = 0
    }
  ]
}

module "dns_record" {

    source = "app.terraform.io/pokt-foundation/gateway/aws//modules/dns/records"
    version = "0.0.1" 

    zone_id        = data.aws_route53_zone.dns_zone.id
    record_name    = "*"
    type    = "A"
    alias = {
        name                   = module.alb.dns_name[0]
        zone_id                = module.alb.zone_id[0]
        evaluate_target_health = "disabled"
        }
}

module "launch_template" {

  source = "app.terraform.io/pokt-foundation/gateway/aws//modules/launch-template/"
  version = "0.0.1" 

  name        = format("%s-%s", local.name, local.environment)
  description = "gateway ecs ec2 launch template"

  # ----------- ssh key ----------
  ssh_key_name   = local.key_name
  ssh_public_key = local.public_key 


  update_default_version  = true  
  disable_api_termination = false

  image_id      = data.aws_ami.amazon_linux.id
  instance_type = "c5a.large"
  key_name      = local.key_name
  ebs_optimized = true

  user_data_base64 = base64encode(local.user_data)

  instance_initiated_shutdown_behavior = "stop"
  # vpc_security_group_ids    = [data.aws_security_group.ecs_sg.id]
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
}

module "autoscaling" {

  source = "app.terraform.io/pokt-foundation/gateway/aws//modules/autoscaling/"
  version = "0.0.1" 

  name  = format("%s-%s", local.name, local.environment)

  # ----------  autoscaling group ----------
  min_size                = 0
  max_size                = 50
  target_group_arns       = module.alb.target_group_arns
  launch_template_id      = module.launch_template.id
  launch_template_version = module.launch_template.latest_version
  vpc_zone_identifier     = module.vpc.public_subnet_ids
  service_linked_role_arn = data.aws_iam_role.autoscaling.arn
  termination_policies    = ["OldestLaunchTemplate", "OldestInstance"]
  protect_from_scale_in   = false

  health_check_type         = "EC2" #"ELB"
  health_check_grace_period = 300

  default_cooldown          = 300


  force_delete   = false
  delete_timeout = "5m" 

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
  tags_as_map = local.tags_as_map

  # ------------ capacity provider ----------
  
  auto_scaling_group_arn = module.autoscaling.autoscaling_group_arn
  managed_scaling_status = "ENABLED"
  managed_scaling_instance_warmup_period = 300
  managed_scaling_target_capacity = 100
}

module "ecs" {

  source = "app.terraform.io/pokt-foundation/gateway/aws//modules/app"
  version = "0.0.1" 

  name   = format("%s-%s", local.name, local.environment)
  
  # ---------- ecs cluster ----------
  create_ecs_cluster = true

  capacity_providers = [module.autoscaling.capacity_provider_name]
  default_capacity_provider_strategy = [{
      capacity_provider = module.autoscaling.capacity_provider_name
      weight            = "1"
      base              = "1" 
      }]
  
  kms_key_id         = null
  logging            = "NONE"

  setting_name       = "containerInsights"
  container_insights = true    

  # ---------- ecs task definition ----------
  create_task_definition = true

  family                   = "${local.name}-${local.environment}"
  task_role_arn            = "${data.aws_iam_role.ecs_task_execution_role.arn}"
  execution_role_arn       = "${data.aws_iam_role.ecs_task_execution_role.arn}"
  cpu                      = 2048
  memory                   = 3883
  network_mode             = "bridge"
  requires_compatibilities = ["EC2"]
  container_definitions = local.container_definitions
  volumes = [
        {
            host_path = "/var/run/docker.sock"
            name      = "docker_sock"
        }, 
        {
            host_path = "/proc/"
            name      = "proc"
        }, 
        {
            host_path = "/sys/fs/cgroup/"
            name      = "cgroup" 
        }
    ]

  # ---------- ecs service  ----------
  create_ecs_service = true

  service_name = "${local.name}-${local.environment}"
  capacity_provider_strategy = [{
    	capacity_provider =  module.autoscaling.capacity_provider_name
			weight            = "1"
			base              = "1"
  }]
  desired_count                       = 3 
  scheduling_strategy 			        	= "REPLICA"
  deployment_minimum_healthy_percent 	= 100
  deployment_maximum_percent			    = 200	
  health_check_grace_period_seconds	  = 90
  
  load_balancer = [{
      target_group_arn = module.alb.target_group_arns[0]
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
  resource_id         = format("service/%s/%s", module.ecs.cluster_name, module.ecs.service_name)
  scalable_dimension  = "ecs:service:DesiredCount"
  role_arn            = data.aws_iam_role.ecs_autoscale_role.arn
  min_capacity        = 3
  max_capacity        = 50 

  # ---------- application autoscaling policy ----------
  create_appautoscaling_policy = true

  policy_name            = "${local.name}-${local.environment}-TargetTrackingScalling"
  policy_type            = "TargetTrackingScaling"
  predefined_metric_type = "ECSServiceAverageCPUUtilization"
  target_value       = 10
  scale_in_cooldown  = 300
  scale_out_cooldown = 300
  disable_scale_in   = false 

}
