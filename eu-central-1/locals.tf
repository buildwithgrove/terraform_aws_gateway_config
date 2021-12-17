locals {
  name        = "gateway"
  environment = "terraform"
  region      = "eu-central-1"

  tags = {
    Environment = local.environment
    Project     = "Gateway"
    Automation  = "true"
    Owner       = "DevOps team"
    }  

  create_task_definition = true
  domain_name = format("*.%s.pokt.network", local.name)

  user_data = <<EOF
  #!/bin/bash
  echo 'ECS_CLUSTER=${local.name}-${local.environment}' >> /etc/ecs/ecs.config
  echo 'ECS_DISABLE_PRIVILEGED=true' >> /etc/ecs/ecs.config
  echo 'ECS_ENABLE_CONTAINER_METADATA=true' >> /etc/ecs/ecs.config
  EOF
  
  public_subnets  = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]

    # ----------- ssh key ----------
   key_name   = "gateway-infra"
   public_key     = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCbkaq3ikeIw0Wi5PHsQ1AxDpzMq6IPxRLubz/FSkFEfPWj73aM6gwaqwNUVH5k5C2HESO3VDEyjhsb6/fy1IXXTEhhfB8OYL+FXNvN+EgwXHdTWvT86DBzWxtWyL/ZB1YpnxXcXmoR24FgGewHNyj8XS4VVG9dvwNfJ7Dg6QTeB+nTT9v6vqaCiklbmsl0yPlyu1uupkj5D0zmaBAa6EPvhLHfUsWdSt33D2MQb5XRXmbfnEhQnBFqcQsV+5sWVVK2BAln3wKnKiiaU+fbP2hoLc8MGCGT2IvK7RH7o4jbUaRTbMJUrvLzvnazKB/X+q/Rb+ixGIqsndmBQd0LYzWd"

  tags_as_map = {
    Name       = format("%s-%s", local.name, local.environment)
  }  
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
			"image": "${module.ecr.repository_url}:latest",
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