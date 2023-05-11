### Create sec group
resource "aws_security_group" "migration" {
  name        = local.name
  description = "Allow ${local.name} inbound traffic"
  vpc_id      = local.vpc_id

  ingress {
    description      = local.name
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    # ipv6_cidr_blocks = 
  }
  ingress {
    description      = local.name
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    # ipv6_cidr_blocks = 
  }
  ingress {
    description      = local.name
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    # ipv6_cidr_blocks = 
  }
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "allow_tls"
  }
}

module "gateway_load_balancing" {
  source  = "app.terraform.io/pokt-foundation/gateway/aws//modules/load_balancing"
  version = "1.0.1"
  
  name                       = "${local.name}-migration"
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
}

### ALB
module "alb" {
  source  = "terraform-aws-modules/alb/aws"
  version = "~> 8.0"

  name = local.name

  load_balancer_type = "application"

  vpc_id             = local.vpc_id
  subnets            = data.aws_subnet_ids.subnets.ids
  security_groups    = [aws_security_group.migration.id]

  # access_logs = {
  #   bucket = "my-alb-logs"
  # }

  target_groups = [
    {
      name_prefix                       = "h1"
      backend_protocol                  = "HTTP"
      backend_port                      = 80
      target_type                       = "instance"
      deregistration_delay              = 10
      # load_balancing_cross_zone_enabled = false
      # health_check = {
      #   enabled             = true
      #   interval            = 30
      #   path                = "/healthz"
      #   port                = "traffic-port"
      #   healthy_threshold   = 3
      #   unhealthy_threshold = 3
      #   timeout             = 6
      #   protocol            = "HTTP"
      #   matcher             = "200-399"
      # }
      protocol_version = "HTTP1"
      targets = {
        # my_ec2 = {
        #   target_id = aws_instance.this.id
        #   port      = 80
        # },
        # my_ec2_again = {
        #   target_id = aws_instance.this.id
        #   port      = 8080
        # }
      }
      # tags = {
      #   InstanceTargetGroupTag = "baz"
      # }
    },
  ]


  https_listeners = [
    {
      port               = 443
      protocol           = "HTTPS"
      certificate_arn    = local.certificate_arn
      target_group_index = 0
    },
  ]

  tags = {
    Environment = "Migration"
  }
}

### ASG
module "asg" {
  source  = "terraform-aws-modules/autoscaling/aws"
  version = ">= 6.9.0, < 7.0.0"

  # Autoscaling group
  name            = local.name
  # use_name_prefix = true
  instance_name   = local.name

  min_size                  = 1
  max_size                  = 3
  desired_capacity          = 1
  wait_for_capacity_timeout = 0
  default_instance_warmup   = 300
  health_check_type         = "EC2"

  vpc_zone_identifier       = data.aws_subnet_ids.subnets.ids
  # service_linked_role_arn   = aws_iam_service_linked_role.autoscaling.arn

  # Launch template
  launch_template_name        = local.name
  launch_template_description = "${local.name} LT"
  update_default_version      = true

  image_id          = data.aws_ami.amazon_linux.id
  instance_type     = local.instance_type
  user_data         = base64encode(local.user_data)
  ebs_optimized     = true
  enable_monitoring = true

  key_name = local.key_name

  network_interfaces = [
    {
      associate_public_ip_address = true
      # security_groups       = [aws_security_group.migration.id]
    }
  ]

  security_groups          = [aws_security_group.migration.id]

  target_group_arns = module.alb.target_group_arns                              

  # Target scaling policy schedule based on average CPU load
  scaling_policies = {
    avg-cpu-policy-greater-than-50 = {
      policy_type               = "TargetTrackingScaling"
      estimated_instance_warmup = 300
      target_tracking_configuration = {
        predefined_metric_specification = {
          predefined_metric_type = "ASGAverageCPUUtilization"
        }
        target_value = 50.0
      }
    },
  }

  block_device_mappings = [
    {
      # Root volume
      device_name = "/dev/xvda"
      no_device   = 0
      ebs = {
        delete_on_termination = true
        encrypted             = true
        volume_size           = 50
        volume_type           = "gp2"
      }
    }
  ]

  tag_specifications = [
    {
      resource_type = "instance"
      tags          = { WhatAmI = "Instance" }
    },
    {
      resource_type = "volume"
      tags          = merge({ WhatAmI = "Volume" })
    }
  ]

  tags = local.tags

}