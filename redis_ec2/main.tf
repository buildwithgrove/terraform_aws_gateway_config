provider "aws" {
  region     = local.region
  access_key = var.aws_access_key_id
  secret_key = var.aws_secret_access_key
  default_tags {
    tags = local.tags
  }
}

locals {
    name        = "redis-cli"
    environment = var.environment
    region      = var.region
    tags = {
    Project     = "Gateway"
    Automation  = "true"
    Owner       = "DevOps team"
    } 
}

module "cli_sg" {

  source  = "app.terraform.io/pokt-foundation/gateway/aws//modules/security_groups"
  version = "1.0.1" 

  #----- security group --------
  name        = format("%s-%s-%s", local.name, "ecs", local.environment)
  vpc_id      = data.aws_vpc.gateway_vpc.id
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

module "redis_cli" {

    # redis cli launch template

    source  = "app.terraform.io/pokt-foundation/gateway/aws//modules/launch-template"
    version = "1.0.1" 

    description = "redis ec2 launch template"
    update_default_version  = true  
    disable_api_termination = false

    image_id        = data.aws_ami.linux.id
    create_key_pair = false
    key_name        = "gateway-infra"
    instance_type   = "t2.micro"
    ebs_optimized   = true


    instance_initiated_shutdown_behavior = "stop"
    iam_instance_profile_name = data.aws_iam_instance_profile.gateway.name

    enable_monitoring           = true
    associate_public_ip_address = true
    block_device_mappings = [
        {
        # Root volume
        device_name = "/dev/sda1"
        no_device   = 0
        virtual_name =  null
        ebs = {
            delete_on_termination = true
            encrypted             = false
            volume_size           = 8
            volume_type           = "gp3"
            iops                  = 100
            kms_key_id            = null
            snapshot_id           = null
            throughput            = 125
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
        security_groups             = [data.aws_security_group.ecs_sg.id]
        subnet_id                   = tolist(data.aws_subnet_ids.gateway_subnets.ids)[0]
        associate_public_ip_address = true
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

resource "aws_instance" "redis_cli" {
    launch_template {
        id      = module.redis_cli.id
        version = module.redis_cli.latest_version
    }
}