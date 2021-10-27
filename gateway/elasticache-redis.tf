
resource "aws_elasticache_subnet_group" "redis_subnets" {
  name          = "redis-subnet-group"
  description   = "provide redis with all the subnets associated with it"
  subnet_ids    = [aws_subnet.gateway_public_sn_01.id,
                  aws_subnet.gateway_public_sn_02.id,
                  aws_subnet.gateway_public_sn_03.id]
}


resource "aws_elasticache_replication_group" "redis" {
  engine                        = "redis"
  engine_version                = "6.x"
  port                          = 6379
  parameter_group_name          = "default.redis6.x"
  node_type                     = "cache.r6g.xlarge"
  multi_az_enabled              = true 
  automatic_failover_enabled    = true
  availability_zones            = ["${var.region}a", "${var.region}b", "${var.region}c"]
  replication_group_id          = "gateway-redis-${var.environment}"
  replication_group_description = "gateway redis elasticache"
  number_cache_clusters         = 3
  subnet_group_name             = "${aws_elasticache_subnet_group.redis_subnets.name}"
  security_group_ids            = [aws_security_group.redis_sg.id]
  at_rest_encryption_enabled    = true 
  tags = {
      Name = "${var.elasticache_replication_group_id}-${var.environment}"
    }
}