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

data "aws_iam_role" "ecs_autoscale_role" {
  name = "AWSServiceRoleForApplicationAutoScaling_ECSService"
}

data "aws_iam_role" "ecs_task_execution_role" {
  name = "ecsTaskExecutionRole"
}

data "aws_route53_zone" "dns_zone" {
  name = format("%s-%s.pokt.network", local.name, local.environment)
} 


data "aws_iam_instance_profile" "gateway" {
  name = local.name
}

data "aws_iam_role" "autoscaling" {
  name = "AWSServiceRoleForAutoScaling"
}