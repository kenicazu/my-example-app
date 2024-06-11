variable "general" {
  description = "General parameters for configuration"
  type        = map(string)
  default = {
    name = "ecs-core"
  }
}

variable "account" {
  description = "Generic parameters for the variable"
  type        = map(string)
  default = {
    region = "us-east-1"
  }
}

variable "network" {
  description = "Parameter for Networking"
  type        = map(string)
  default = {
    vpc_cidr                      = "10.0.0.0/16"
    enable_nat_gateway            = true
    single_nat_gateway            = true
    enable_dns_hostnames          = true
    manage_default_network_acl    = true
    manage_default_route_table    = true
    manage_default_security_group = true
  }
}

variable "ecs" {
  description = "Parameter for ECS Cluster"
  type        = map(string)
  default = {
    name                                   = "ecs-core"
    instance_type                          = "t3.xlarge"
    capacity_provider_name                 = "core-infra"
    default_capacity_provider_use_fargate  = false
    managed_termination_protection         = "ENABLED"
    create_task_exec_iam_role              = false
    cloud_watch_log_group_name             = "/aws/ecs/aws-ec2"
    cloudwatch_log_group_retention_in_days = 7
    cloud_watch_encryption_enabled         = true
  }
}

variable "ecs_managed_scaling" {
  description = "Parameter for ECS managed scaling"
  type        = map(string)
  default = {
    maximum_scaling_step_size = 5
    minimum_scaling_step_size = 1
    status                    = "ENABLED"
    target_capacity           = 60
  }
}

variable "ecs_default_capacity_provider_strategy" {
  description = "Parameter for ECS capacity provider"
  type        = map(string)
  default = {
    weight = 1
    base   = 1
  }
}

variable "ecs_autoscaling" {
  description = "Parameter for ECS autoscaling"
  type        = map(string)
  default = {
    ignore_desired_capacity_changes = true
    health_check_type               = "EC2"
    min_size                        = 3
    max_size                        = 5
    desired_capacity                = 3
    protect_from_scale_in           = true
  }
}

variable "ecs_autoscaling_sg" {
  description = "Parameter for ECS autoscaling Security Group"
  type        = map(any)
  default = {
    ingress_rules = ["http-80-tcp"]
    egress_rules  = ["all-all"]
  }
}

variable "tags" {
  description = "Generic tags for all resources"
  type        = map(string)
  default = {
    Blueprint  = "ecs-core"
    GithubRepo = "github.com/aws-ia/ecs-blueprints"
  }
}

variable "cluster_settings" {
  description = "Configuration block(s) with cluster settings. For example, this can be used to enable CloudWatch Container Insights for a cluster"
  type        = map(string)
  default = {
    name  = "containerInsights"
    value = "enabled"
  }
}

variable "sns_email_for_cloudwatch_alerts" {
  type    = string
  default = "email_example@example.com"
}

variable "sns_topic_name_for_alerts" {
  type    = string
  default = "containters-ecs-topic-alerts"
}

variable "CPUReservation_threshold" {
  type    = string
  default = 80
}

variable "CPUUtilization_threshold" {
  type    = string
  default = 75
}

variable "MemoryReservation_threshold" {
  type    = string
  default = 75
}

variable "MemoryUtilization_threshold" {
  type    = string
  default = 80
}

