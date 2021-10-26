resource "aws_ecs_service" "ecs-service" {
  	name             					= "${var.ecs-service}-${var.environment}"
  	cluster         					= "${aws_ecs_cluster.gateway.id}"
  	task_definition 					= "${aws_ecs_task_definition.gateway.arn}"
	launch_type 						= "FARGATE"
  	desired_count   					= 3
	platform_version 					= "LATEST"
	scheduling_strategy 				= "REPLICA"
	deployment_minimum_healthy_percent 	= 100
	deployment_maximum_percent			= 200	
	health_check_grace_period_seconds	= 90
	depends_on = [aws_ecs_task_definition.gateway]
    load_balancer {
    	target_group_arn   				= "${aws_lb_target_group.ecs_target_group.arn}"
    	container_port    				= 3000
    	container_name    				= "gateway"
	}
	network_configuration {
		subnets 						= [aws_subnet.gateway_public_sn_01.id, aws_subnet.gateway_public_sn_02.id, aws_subnet.gateway_public_sn_03.id  ]
		security_groups 				= [aws_security_group.ecs_sg.id]
		assign_public_ip 				= true

	}
	deployment_controller {
		type 							= "ECS"
	}
	deployment_circuit_breaker {
		enable  						= false
		rollback 						= true 
	}
	tags = {
		Name = "${var.ecs-service}-${var.environment}"
	}
}
