data "aws_iam_role" "ecs_instance" {
  name = "ecsInstanceRole"
}

data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name = "name"
    values = [
      "amzn2-ami-ecs-hvm-*-x86_64-ebs",
    ]
  }
}

data "aws_ami" "migration_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023*.0-kernel-6.1-x86_64"]
  }
}

data "aws_iam_role" "ecs_autoscale_role" {
  name = "AWSServiceRoleForApplicationAutoScaling_ECSService"
}

data "aws_iam_instance_profile" "gateway" {
  name = "gateway"
}

data "aws_iam_role" "autoscaling" {
  name = "AWSServiceRoleForAutoScaling"
}

data "aws_iam_role" "ecs_task_execution_role" {
  name = "ecsTaskExecutionRole"
}

data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_vpc" "global_dispatcher_vpc" {
  provider = aws.peer
  filter {
     name = "tag:Name"
     values = ["global_dispatcher-prod"]
   }
}

data "aws_route_table" "global_dispatcher" {
    provider = aws.peer
    filter {
        name = "tag:Name"
        values = ["global_dispatcher-private-rt"]   
    }
}