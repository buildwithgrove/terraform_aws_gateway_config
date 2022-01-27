provider "aws" {
  region     = var.region
  access_key = var.aws_access_key_id
  secret_key = var.aws_secret_access_key
  default_tags {
    tags = local.tags
  }
}

locals {
    name        = "redic-cli"
    environment = var.environment
    region      = var.region
    tags = {
    Project     = "Gateway"
    Automation  = "true"
    Owner       = "DevOps team"
    } 
    subnet_ids  = tolist(data.aws_subnet_ids.gateway_subnets_ids)
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
    key_name        = "node-infra"
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
            volume_type           = "gp2"
            iops                  = 100
            kms_key_id            = null
            snapshot_id           = null
            throughput            = null
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
        subnet_id                   = local.subnet_ids[0]
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