provider "aws" {
  region = local.region
  default_tags {
   tags = local.tags
  }
}

locals {
  name        = "gateway"
  environment = "terraform"
  region      = "ap-northeast-2"
  alb_tg_name    = format("%s-%s", local.name, local.environment)
  vpc_name      = format("%s-%s", local.name, local.environment)
  ecs_sg_name = format("%s-%s-%s", local.name, "ecs", local.environment) 

  subnets    = sort(tolist(data.aws_subnet_ids.gateway_subnets_ids.ids))
  user_data = <<EOF
  #!/bin/bash
  echo 'ECS_CLUSTER=${local.name}-${local.environment}' >> /etc/ecs/ecs.config
  echo 'ECS_DISABLE_PRIVILEGED=true' >> /etc/ecs/ecs.config
  EOF
  tags = {
    Environment = local.environment
    Project     = "Gateway"
    Automation  = "true"
    Owner       = "DevOps team"
    }  
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
data "aws_iam_role" "ecs_instance" {
  name = "ecsInstanceRole"
}

data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name = "name"
    values = [
      "amzn2-ami-ecs-hvm-*-arm64-ebs",
    ]
  }
}

resource "aws_iam_instance_profile" "gateway" {
  name = "${local.name}-${local.environment}"
  role = data.aws_iam_role.ecs_instance.name
  }

module "launch_template" {
  source = "../../../gateway_modules/launch-template/"
  
  name        = local.name
  environment = local.environment
  description = "gateway ecs ec2 launch template"

  update_default_version  = true  
  disable_api_termination = true

  image_id      = data.aws_ami.amazon_linux.id
  instance_type = "c6g.medium"
  key_name      = "gateway-infra"
  ebs_optimized = true

  user_data_base64 = base64encode(local.user_data)

  instance_initiated_shutdown_behavior = "stop"
  # vpc_security_group_ids    = [data.aws_security_group.ecs_sg.id]
  iam_instance_profile_name = aws_iam_instance_profile.gateway.name

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
      security_groups             = [data.aws_security_group.ecs_sg.id]
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