resource "aws_lb" "gateway_alb" {
    name                = "${var.application_load_balancer_name}-${var.environment}"
    internal            = false
    load_balancer_type  = "application"
    security_groups     = [aws_security_group.alb_sg.id] 
    subnets             = ["${aws_subnet.gateway_public_sn_01.id}", "${aws_subnet.gateway_public_sn_02.id}"]    
    depends_on          = [aws_internet_gateway.vpc_internet_gw]

    tags = {
      Name = "${var.application_load_balancer_name}-${var.environment}"
    }
}

resource "aws_lb_target_group" "ecs_target_group" {
    name                = "${var.target_group_name}-${var.environment}"
    port                = "3000"
    protocol            = "HTTP"
    protocol_version    = "HTTP1"
    target_type         = "ip"
    vpc_id              = aws_vpc.gateway_vpc.id
    health_check {
      healthy_threshold   = "5"
      unhealthy_threshold = "2"
      timeout             = "5"
      interval            = "30"
      matcher             = "200"
      path                = "/"
      port                = "traffic-port"
      protocol            = "HTTP"
    }
    tags = {
      Name = "${var.target_group_name}-${var.environment}"
    }
}

data "aws_acm_certificate" "ssl_certificate" {
  domain = "${var.ssl_domain}"
  types = ["AMAZON_ISSUED"]
}

resource "aws_lb_listener" "https_listener_1" {
  load_balancer_arn = "${aws_lb.gateway_alb.arn}"
  port              = "3000"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = "${data.aws_acm_certificate.ssl_certificate.arn}"
  default_action {
    type = "forward"
    target_group_arn = "${aws_lb_target_group.ecs_target_group.arn}"
  }
}

resource "aws_lb_listener" "https_listener_2" {
  load_balancer_arn = "${aws_lb.gateway_alb.arn}"
  port = "443"
  protocol = "HTTPS"
  ssl_policy = "ELBSecurityPolicy-2016-08"
  certificate_arn = "${data.aws_acm_certificate.ssl_certificate.arn}"
  default_action {
    type = "forward"
    target_group_arn = "${aws_lb_target_group.ecs_target_group.arn}"
  }
}