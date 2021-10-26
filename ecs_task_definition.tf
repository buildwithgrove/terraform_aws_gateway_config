data "aws_iam_role" "ecs_task_execution_role" {
    name = "ecsTaskExecutionRole"
}

resource "aws_ecs_task_definition" "gateway" {
    family                   = "${var.task_definition_familly}-${var.environment}"
    task_role_arn            = "${data.aws_iam_role.ecs_task_execution_role.arn}"
    execution_role_arn       = "${data.aws_iam_role.ecs_task_execution_role.arn}"
    cpu                      = "${var.fargate_cpu}"
    memory                   = "${var.fargate_memory}"
    network_mode             = "awsvpc"
    requires_compatibilities = ["FARGATE"]
    container_definitions = jsonencode([
       {
        "dnsSearchDomains": null,
        "environmentFiles": null,
        "logConfiguration": {
            "logDriver": "awslogs",
            "secretOptions": null,
            "options": {
                "awslogs-group": "${var.log_group}-${var.environment}",
                "awslogs-region": "${var.region}",
                "awslogs-stream-prefix": "ecs"
            }
        },
        "entryPoint": [],
        "portMappings": [{
            "hostPort": 3000,
            "protocol": "tcp",
            "containerPort": 3000
        }],
        "environment": [],
        "command": [],
        "linuxParameters": null,
        "cpu": 4096,
        "resourceRequirements": null,
        "ulimits": [{
            "name": "nofile",
            "hardLimit": 65535,
            "softLimit": 65535
        }],
        "dnsServers": null,
        "mountPoints": [],
        "workingDirectory": null,
        "dockerSecurityOptions": null,
        "memory": null,
        "memoryReservation": 8192,
        "volumesFrom": [],
        "stopTimeout": null,
        "image": "${var.image_url}",
        "startTimeout": null,
        "firelensConfiguration": null,
        "dependsOn": null,
        "disableNetworking": null,
        "interactive": null,
        "healthCheck": null,
        "essential": true,
        "links": [],
        "hostname": null,
        "extraHosts": null,
        "pseudoTerminal": null,
        "user": null,
        "readonlyRootFilesystem": null,
        "dockerLabels": null,
        "systemControls": null,
        "privileged": null,
        "name": "gateway"
      }])
}
