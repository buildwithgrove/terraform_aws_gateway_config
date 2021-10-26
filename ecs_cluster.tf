resource "aws_cloudwatch_log_group" "gateway" {
  name = "${var.log_group}-${var.environment}"
}

resource "aws_ecs_cluster" "gateway" {
  name = "${var.ecs_cluster}-${var.environment}"
  configuration {
      execute_command_configuration{
              logging    = "OVERRIDE"
              log_configuration {
                cloud_watch_log_group_name = aws_cloudwatch_log_group.gateway.name
                }
        }  
  }
  tags = {
    Name = "${var.ecs_cluster}-${var.environment}"
  }
}