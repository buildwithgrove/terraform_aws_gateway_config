module "code-deploy" {
  source  = "cloudposse/code-deploy/aws"
  version = "0.2.3"
  
  context = module.this.context
  minimum_healthy_hosts = null

  traffic_routing_config = {
    type       = "TimeBasedLinear"
    interval   = 10
    percentage = 10
  }

  deployment_style = {
    deployment_option = "WITH_TRAFFIC_CONTROL"
    deployment_type   = "BLUE_GREEN"
  }

  blue_green_deployment_config = {
    deployment_ready_option = {
      action_on_timeout    = "STOP_DEPLOYMENT"
      wait_time_in_minutes = 10
    }
    terminate_blue_instances_on_deployment_success = {
      action                           = "TERMINATE"
      termination_wait_time_in_minutes = 5
    }
  }

  ecs_service = [
    {
      cluster_name = module.gateway.cluster_name
      service_name = module.gateway.service_name
    }
  ]

  load_balancer_info = {
    target_group_pair_info = {
      prod_traffic_route = {
        listener_arns = module.gateway.https_listener_arns
      }
      blue_target_group = {
        name = module.gateway.target_group_arns[0]
      }
      green_target_group = {
        name = module.gateway.target_group_arns[1]
      }
    }
  }
}