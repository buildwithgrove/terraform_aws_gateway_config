provider "aws" {
  region     = local.region
  access_key = var.aws_access_key_id
  secret_key = var.aws_secret_access_key
  default_tags {
    tags = local.tags
  }
}

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
}

data "aws_iam_role" "ecs_task_execution_role" {
  name = "ecsTaskExecutionRole"
}


module "ecs_task_definition" {
    
    source = "app.terraform.io/pokt-foundation/gateway/aws//modules/app"
    version = "1.0.0"

  # ---------- ecs task definition ----------
  create_task_definition = true

  family                   = "${local.name}-${local.environment}"
  task_role_arn            = "${data.aws_iam_role.ecs_task_execution_role.arn}"
  execution_role_arn       = "${data.aws_iam_role.ecs_task_execution_role.arn}"
  cpu                      = 2048
  memory                   = 3883
  network_mode             = "bridge"
  requires_compatibilities = ["EC2"]
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
    
}