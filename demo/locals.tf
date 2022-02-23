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
  public_subnets  = var.public_subnets

  ingress_with_cidr_blocks = var.ingress_with_cidr_blocks

  instance_type = var.instance_type

  domain_name = var.domain_name
  
  create_key_pair = var.create_key_pair

  az = sort(data.aws_availability_zones.available.names)

  support_container_insights = var.support_container_insights

  container_definitions = jsonencode([
		{
			"dnsSearchDomains": null,
			"environmentFiles": null,
			"logConfiguration": {
			"logDriver": "json-file",
			"options": {
				"max-size": "10m",
				"max-file": "3"
			}
			},
			"entryPoint": [],
			"portMappings": [
			{
				"hostPort": 3000,
				"protocol": "tcp",
				"containerPort": 3000
			}],
			"environment": [],
			"command": [],
			"linuxParameters": null,
			"cpu": 1024,
			"resourceRequirements": null,
			"ulimits": [
				{
					"name": "nofile",
					"hardLimit": 65535,
					"softLimit": 65535
				}
			],
			"dnsServers": null,
			"mountPoints": [],
			"workingDirectory": null,
			"dockerSecurityOptions": null,
			"memory": null,
			"memoryReservation": 2048,
			"volumesFrom": [],
			"stopTimeout": null,
			"image": "initial:latest",
			"startTimeout": null,
			"firelensConfiguration": null,
			"dependsOn":[{
				"containerName": "datadog-agent",
				"condition": "START"
			}],
			"disableNetworking": null,
			"interactive": null,
			"healthCheck": null,
			"essential": true,
			"links": [
				"datadog-agent"
			],
			"hostname": null,
			"extraHosts": null,
			"pseudoTerminal": null,
			"user": null,
			"readonlyRootFilesystem": null,
			"dockerLabels": null,
			"systemControls": null,
			"privileged": null,
			"name": "gateway"
		}, 
		{
            "dnsSearchDomains": null,
            "environmentFiles": null,
            "logConfiguration": {
                "logDriver": "json-file",
                "options": {
                    "max-size": "10m",
                    "max-file": "3"
                }
            },
            "entryPoint": [],
            "portMappings": [
                {
                    "hostPort": 8126,
                    "protocol": "tcp",
                    "containerPort": 8126
                },
                {
                    "hostPort": 8125,
                    "protocol": "udp",
                    "containerPort": 8125
                }
            ],
            "command": [],
            "linuxParameters": null,
            "cpu": 512,
            "environment": [],
            "resourceRequirements": null,
            "ulimits": [
                {
                    "name": "nofile",
                    "softLimit": 65535,
                    "hardLimit": 65535
                }
            ],
            "dnsServers": null,
            "mountPoints": [
                {
                    "readOnly": null,
                    "containerPath": "/var/run/docker.sock",
                    "sourceVolume": "docker_sock"
                },
                {
                    "readOnly": null,
                    "containerPath": "/host/sys/fs/cgroup",
                    "sourceVolume": "cgroup"
                },
                {
                    "readOnly": null,
                    "containerPath": "/host/proc",
                    "sourceVolume": "proc"
                }
            ],
            "workingDirectory": null,
            "secrets": null,
            "dockerSecurityOptions": null,
            "memory": null,
            "memoryReservation": 1024,
            "volumesFrom": [],
            "stopTimeout": null,
            "image": "gcr.io/datadoghq/agent:latest",
            "startTimeout": null,
            "firelensConfiguration": null,
            "disableNetworking": null,
            "interactive": null,
            "healthCheck":  {
                "retries": 3,
                "command": ["CMD-SHELL","agent health"],
                "timeout": 5,
                "interval": 30,
                "startPeriod": 15
            },
            "essential": true,
            "hostname": null,
            "extraHosts": null,
            "pseudoTerminal": null,
            "user": null,
            "readonlyRootFilesystem": null,
            "dockerLabels": null,
            "systemControls": null,
            "privileged": null,
            "name": "datadog-agent"
        }
])
}