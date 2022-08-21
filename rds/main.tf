module "rds_sg" {

  source  = "app.terraform.io/pokt-foundation/gateway/aws//modules/security_groups"
  version = "1.0.1"

  #----- security group --------
  name = "portal-api-postgres"
  #name        = format("%s-%s-%s", local.name, "ecs", local.environment)
  vpc_id = data.aws_vpc.selected.id
  #description = format("%s %s security group", local.name, "ecs")

  timeout_sg_create = "5m"
  timeout_sg_delete = "7m"

  #----- rules --------
  #ingress_with_cidr_blocks = local.ingress_with_cidr_blocks == [] ? null : local.ingress_with_cidr_blocks

  #ingress_with_source_security_group_id = [{
  #  rule                     = "public-access"
  #  source_security_group_id = module.alb_sg.id
  #}]

    # ingress
  ingress_with_cidr_blocks = [
    {
      from_port   = 5432
      to_port     = 5432
      protocol    = "tcp"
      description = "Public PostgreSQL access"
      #cidr_blocks = module.vpc.vpc_cidr_block
      cidr_blocks = "0.0.0.0/0"
    },
  ]

  egress_with_cidr_blocks = [{
    rule        = "all-all"
    cidr_blocks = "0.0.0.0/0"
  }]

}

module "rds" {
  source  = "app.terraform.io/pokt-foundation/rds/aws"
  version = "1.0.0"

  identifier = "portal-api"

  engine                = "postgres"
  engine_version        = "14.1"
  instance_class        = "db.t4g.medium"
  allocated_storage     = 100
  max_allocated_storage = 1000

  #db_name  = "portal-api"
  username = "pocket"
  port     = 5432

  iam_database_authentication_enabled = false

  #vpc_security_group_ids = data.aws_security_group.rds_sg.id

  maintenance_window = "Mon:00:00-Mon:03:00"
  backup_window      = "03:00-06:00"

  # Enhanced Monitoring - see example for details on how to create the role
  # by yourself, in case you don't want to create it automatically

  publicly_accessible = true
  multi_az            = true


  performance_insights_enabled          = true
  performance_insights_retention_period = 7
  create_monitoring_role                = true
  monitoring_interval                   = 60
  monitoring_role_name                  = "example-monitoring-role-name"
  monitoring_role_use_name_prefix       = true
  monitoring_role_description           = "Description for monitoring role"

  #iops = 
  #kms_key_id = var.kms_key_id


  # DB subnet group
  #create_db_subnet_group = true
  create_db_subnet_group = false
  db_subnet_group_name   = "default-vpc-49658c31"

  subnet_ids = data.aws_subnets.selected.ids

  # DB parameter group
  family                    = "postgres14"
  create_db_parameter_group = false
  parameter_group_name      = "default:postgres14"

  # DB option group
  create_db_option_group = false
  option_group_name      = "default:postgres-14"
  major_engine_version   = "14"

  # Database Deletion Protection
  deletion_protection = true

  # Back Up
  #backup_retention_period = 7

  # Logs
  #enabled_cloudwatch_logs_exports = ["postgresql", "upgrade"]
  #create_cloudwatch_log_group     = true

}

