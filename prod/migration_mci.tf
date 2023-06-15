locals {
  mci_user_data = <<-EOT
    #!/bin/bash
    set -x

    sudo cat <<EOF >> /etc/sysctl.d/99-sysctl.conf
    fs.file-max = 262144
    EOF
    sudo sysctl -p

    sudo yum update
    sudo yum install -y nginx

    cat <<EOF > /tmp/nginx.conf
    user nginx;
    worker_processes auto;
    error_log /dev/null;
    pid /run/nginx.pid;

    # Load dynamic modules. See /usr/share/doc/nginx/README.dynamic.
    include /usr/share/nginx/modules/*.conf;

    events {
        worker_connections 9182;
    }

    http {
        log_format  main  '\$remote_addr - \$remote_user [\$time_local] "\$request" '
                          '\$status \$body_bytes_sent "\$http_referer" '
                          '"\$http_user_agent" "\$http_x_forwarded_for"';

        access_log  /var/log/nginx/access.log  main;

        sendfile            on;
        tcp_nopush          on;
        keepalive_timeout   65;
        types_hash_max_size 4096;

        include             /etc/nginx/mime.types;
        default_type        application/octet-stream;

        # Load modular configuration files from the /etc/nginx/conf.d directory.
        # See http://nginx.org/en/docs/ngx_core_module.html#include
        # for more information.
        include /etc/nginx/conf.d/*.conf;


    map \$http_host \$backend {
        ~^(?<subdomain>.+)\.gateway\.pokt\.network\$ https://\$subdomain.middleware.${var.gcp_region}-portal-prd.v2.pokt.network;
    }

    resolver 8.8.8.8;

    server {
        listen 80;
        access_log /dev/null;
        server_name *.gateway.pokt.network;

        # Ensure requests are sent with the original host header
        proxy_set_header Host \$host;

        # Support for POST requests with bodies
        client_max_body_size 100m;

        location / {
            # Proxy to the appropriate backend
            proxy_pass \$backend;
            proxy_http_version 1.1;
            proxy_set_header Upgrade \$http_upgrade;
            proxy_set_header Connection "upgrade";
            proxy_set_header X-Real-IP \$remote_addr;
            proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto \$scheme;
            add_header 'Access-Control-Allow-Origin' '*';
            add_header 'Access-Control-Allow-Methods' 'GET, POST';
            add_header 'Access-Control-Allow-Headers' 'DNT,User-Agent,X-Requested-With,If-Modified-Since,Cache-Control,Content-Type,Range';
            add_header 'Access-Control-Expose-Headers' 'Content-Length,Content-Range';
        }

        location /healthz {
            return 200 'Healthy';
            add_header Content-Type text/plain;
        }
      }
    }
    EOF
    sudo mv /tmp/nginx.conf /etc/nginx/nginx.conf

    sudo systemctl enable nginx
    sudo systemctl restart nginx
    sudo systemctl status nginx
    echo "All DONE!"
  EOT
}

### Create sec group
resource "aws_security_group" "migration" {
  name        = "${local.name}-mci"
  description = "Allow ${local.name} inbound traffic"
  vpc_id      = module.gateway.vpc_id

  ingress {
    description = local.name
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    # ipv6_cidr_blocks = 
  }
  ingress {
    description = local.name
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    # ipv6_cidr_blocks = 
  }
  ingress {
    description = local.name
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
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
    Name = "${local.name}-mci"
  }
}

module "gateway_load_balancing" {
  source  = "app.terraform.io/pokt-foundation/gateway/aws//modules/load_balancing"
  version = "1.0.1"

  name                       = "${local.name}-mci"
  vpc_id                     = module.gateway.vpc_id
  load_balancer_type         = "application"
  internal                   = false
  security_groups            = [aws_security_group.migration.id]
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
      name                          = format("%s-mci", local.name)
      port                          = 80
      protocol                      = "HTTP"
      protocol_version              = "HTTP1"
      target_type                   = "instance"
      deregistration_delay          = 120
      load_balancing_algorithm_type = "least_outstanding_requests"

      health_check = {
        enabled             = true
        interval            = 30
        path                = "/healthz"
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
      load_balancer_arn  = module.gateway_load_balancing.arn[0]
      port               = 443
      protocol           = "HTTPS"
      certificate_arn    = module.gateway.ssl_arn[0]
      ssl_policy         = "ELBSecurityPolicy-TLS13-1-2-2021-06"
      action_type        = "forward"
      target_group_index = 0
    }
  ]
}

module "gateway_launch-template" {
  source  = "app.terraform.io/pokt-foundation/gateway/aws//modules/launch-template"
  version = "1.0.1"

  name                    = "${local.name}-mci"
  description             = "gateway migration ec2 launch template"
  update_default_version  = true
  disable_api_termination = false

  image_id        = data.aws_ami.migration_linux.id
  key_name        = "gateway-infra"
  create_key_pair = false
  instance_type   = "m5.large"
  ebs_optimized   = true

  user_data_base64 = base64encode(local.mci_user_data)

  instance_initiated_shutdown_behavior = "stop"
  iam_instance_profile_name            = data.aws_iam_instance_profile.gateway.name

  enable_monitoring           = true
  associate_public_ip_address = true
  block_device_mappings = [
    {
      # Root volume
      device_name  = "/dev/xvda"
      no_device    = 0
      virtual_name = null
      ebs = {
        delete_on_termination = true
        encrypted             = false
        volume_size           = 50
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
      security_groups             = [aws_security_group.migration.id]
      associate_public_ip_address = true
      # interface_type              = "Network interface"
    },
  ]

  tag_specifications = [
    {
      resource_type = "instance"
      tags = merge(
        {
          Name = "${local.name}-mci"
        },
        local.tags,
      )
    },
    {
      resource_type = "volume"
      tags = merge(
        {
          Name = "${local.name}-mci"
        },
        local.tags,
      )
    }
  ]

}

module "gateway_autoscaling" {
  source  = "app.terraform.io/pokt-foundation/gateway/aws//modules/autoscaling"
  version = "1.0.1"

  name                    = "${local.name}-mci"
  min_size                = 3
  max_size                = 12
  desired_capacity        = 3
  target_group_arns       = module.gateway_load_balancing.target_group_arns
  launch_template_id      = module.gateway_launch-template.id
  launch_template_version = module.gateway_launch-template.latest_version
  vpc_zone_identifier     = module.gateway.public_subnet_ids
  service_linked_role_arn = data.aws_iam_role.autoscaling.arn
  termination_policies    = ["OldestLaunchTemplate", "OldestInstance"]
  protect_from_scale_in   = false
  auto_scaling_group_arn  = module.gateway_autoscaling.autoscaling_group_arn


  health_check_type         = "EC2"
  health_check_grace_period = 150
  wait_for_capacity_timeout = 0

  default_cooldown = 150


  force_delete = false

  instance_refresh = {
    strategy = "Rolling"
    triggers = ["tag"]
    preferences = {
      instance_warmup        = 120
      min_healthy_percentage = 90
    }
  }
  tags_as_map = {
    Name = format("%s-mci", local.name)
  }
}

resource "aws_autoscaling_policy" "avg-cpu-policy-greater-than-50" {
  autoscaling_group_name = module.gateway_autoscaling.autoscaling_group_name
  name                   = "gateway-mci"
  policy_type            = "TargetTrackingScaling"

  estimated_instance_warmup = 300
  target_tracking_configuration {
    target_value = 50.0
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }
  }
}
