locals {
  name        = var.name
  environment = var.environment
  region      = var.region
  tags = {
    Environment = local.environment
    Project     = "Gateway"
    Automation  = "true"
    Owner       = "DevOps team"
  }
  public_subnets = var.public_subnets

  ingress_with_cidr_blocks = var.ingress_with_cidr_blocks

  instance_type = var.instance_type

  domain_name = var.domain_name

  create_key_pair = var.create_key_pair

  az = sort(data.aws_availability_zones.available.names)

  support_container_insights = var.support_container_insights

  user_data = <<-EOT
    #!/bin/bash
    set -x

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
        ~^(?<subdomain>.+)\.gateway\.pokt\.network\$ https://\$subdomain.middleware.${var.gcp_region}-prod.v2.pokt.network;
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

  container_definitions = jsonencode([
    {
      "dnsSearchDomains" : null,
      "environmentFiles" : null,
      "logConfiguration" : {
        "logDriver" : "json-file",
        "options" : {
          "max-size" : "10m",
          "max-file" : "3"
        }
      },
      "entryPoint" : [],
      "portMappings" : [
        {
          "hostPort" : 3000,
          "protocol" : "tcp",
          "containerPort" : 3000
      }],
      "environment" : [],
      "command" : [],
      "linuxParameters" : null,
      "cpu" : 1024,
      "resourceRequirements" : null,
      "ulimits" : [
        {
          "name" : "nofile",
          "hardLimit" : 65535,
          "softLimit" : 65535
        }
      ],
      "dnsServers" : null,
      "mountPoints" : [],
      "workingDirectory" : null,
      "dockerSecurityOptions" : null,
      "memory" : null,
      "memoryReservation" : 2048,
      "volumesFrom" : [],
      "stopTimeout" : null,
      "image" : "initial:latest",
      "startTimeout" : null,
      "firelensConfiguration" : null,
      "dependsOn" : [{
        "containerName" : "datadog-agent",
        "condition" : "START"
      }],
      "disableNetworking" : null,
      "interactive" : null,
      "healthCheck" : null,
      "essential" : true,
      "links" : [
        "datadog-agent"
      ],
      "hostname" : null,
      "extraHosts" : null,
      "pseudoTerminal" : null,
      "user" : null,
      "readonlyRootFilesystem" : null,
      "dockerLabels" : null,
      "systemControls" : null,
      "privileged" : null,
      "name" : "gateway"
    },
    {
      "dnsSearchDomains" : null,
      "environmentFiles" : null,
      "logConfiguration" : {
        "logDriver" : "json-file",
        "options" : {
          "max-size" : "10m",
          "max-file" : "3"
        }
      },
      "entryPoint" : [],
      "portMappings" : [
        {
          "hostPort" : 8126,
          "protocol" : "tcp",
          "containerPort" : 8126
        },
        {
          "hostPort" : 8125,
          "protocol" : "udp",
          "containerPort" : 8125
        }
      ],
      "command" : [],
      "linuxParameters" : null,
      "cpu" : 512,
      "environment" : [],
      "resourceRequirements" : null,
      "ulimits" : [
        {
          "name" : "nofile",
          "softLimit" : 65535,
          "hardLimit" : 65535
        }
      ],
      "dnsServers" : null,
      "mountPoints" : [
        {
          "readOnly" : null,
          "containerPath" : "/var/run/docker.sock",
          "sourceVolume" : "docker_sock"
        },
        {
          "readOnly" : null,
          "containerPath" : "/host/sys/fs/cgroup",
          "sourceVolume" : "cgroup"
        },
        {
          "readOnly" : null,
          "containerPath" : "/host/proc",
          "sourceVolume" : "proc"
        }
      ],
      "workingDirectory" : null,
      "secrets" : null,
      "dockerSecurityOptions" : null,
      "memory" : null,
      "memoryReservation" : 1024,
      "volumesFrom" : [],
      "stopTimeout" : null,
      "image" : "gcr.io/datadoghq/agent:latest",
      "startTimeout" : null,
      "firelensConfiguration" : null,
      "disableNetworking" : null,
      "interactive" : null,
      "healthCheck" : {
        "retries" : 3,
        "command" : ["CMD-SHELL", "agent health"],
        "timeout" : 5,
        "interval" : 30,
        "startPeriod" : 15
      },
      "essential" : true,
      "hostname" : null,
      "extraHosts" : null,
      "pseudoTerminal" : null,
      "user" : null,
      "readonlyRootFilesystem" : null,
      "dockerLabels" : null,
      "systemControls" : null,
      "privileged" : null,
      "name" : "datadog-agent"
    }
  ])
}
