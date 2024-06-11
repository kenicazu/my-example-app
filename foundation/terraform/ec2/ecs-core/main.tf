provider "aws" {
  region = var.account.region
}

data "aws_availability_zones" "available" {}
data "aws_caller_identity" "current" {}

locals {
  name      = basename(path.cwd)
  azs       = slice(data.aws_availability_zones.available.names, 0, 3)
  user_data = <<-EOT
    #!/bin/bash
    cat <<'EOF' >> /etc/ecs/ecs.config
    ECS_CLUSTER=${var.ecs.name}
    ECS_LOGLEVEL=debug
    ECS_ENABLE_TASK_IAM_ROLE=true
    EOF
  EOT
}

################################################################################
# ECS Blueprint
################################################################################

module "ecs_cluster" {
  source  = "terraform-aws-modules/ecs/aws//modules/cluster"
  version = "~> 5.0"

  cluster_name = var.ecs.name

  cluster_configuration = {
    execute_command_configuration = {
      logging = "OVERRIDE"
      log_configuration = {
        cloud_watch_log_group_name     = var.ecs.cloud_watch_log_group_name
        cloud_watch_encryption_enabled = var.ecs.cloud_watch_encryption_enabled
      }
    }
  }
  cloudwatch_log_group_retention_in_days = var.ecs.cloudwatch_log_group_retention_in_days

  cluster_service_connect_defaults = {
    namespace = aws_service_discovery_private_dns_namespace.this.arn
  }

  # Capacity provider - autoscaling groups
  default_capacity_provider_use_fargate = var.ecs.default_capacity_provider_use_fargate
  autoscaling_capacity_providers = {
    (var.ecs.capacity_provider_name) = {
      auto_scaling_group_arn         = module.autoscaling.autoscaling_group_arn
      managed_termination_protection = var.ecs.managed_termination_protection

      managed_scaling = {
        maximum_scaling_step_size = var.ecs_managed_scaling.maximum_scaling_step_size
        minimum_scaling_step_size = var.ecs_managed_scaling.minimum_scaling_step_size
        status                    = var.ecs_managed_scaling.status
        target_capacity           = var.ecs_managed_scaling.target_capacity
      }

      default_capacity_provider_strategy = {
        weight = var.ecs_default_capacity_provider_strategy.weight
        base   = var.ecs_default_capacity_provider_strategy.base
      }
    }
  }

  # Shared task execution role
  create_task_exec_iam_role = var.ecs.create_task_exec_iam_role
  # Allow read access to all SSM params in current account for demo
  task_exec_ssm_param_arns = ["arn:aws:ssm:${var.account.region}:${data.aws_caller_identity.current.account_id}:parameter/*"]
  # Allow read access to all secrets in current account for demo
  task_exec_secret_arns = ["arn:aws:secretsmanager:${var.account.region}:${data.aws_caller_identity.current.account_id}:secret:*"]

  tags = var.tags

  # ContainerInsights (https://registry.terraform.io/modules/terraform-aws-modules/ecs/aws/latest#input_cluster_settings)
  cluster_settings = var.cluster_settings
}

resource "aws_service_discovery_private_dns_namespace" "this" {
  name        = "default.${var.general.name}.local"
  description = "Service discovery namespace.${var.ecs.name}.local"
  vpc         = module.vpc.vpc_id

  tags = var.tags
}

################################################################################
# Supporting Resources
################################################################################

# https://docs.aws.amazon.com/AmazonECS/latest/developerguide/ecs-optimized_AMI.html#ecs-optimized-ami-linux
data "aws_ssm_parameter" "ecs_optimized_ami" {
  name = "/aws/service/ecs/optimized-ami/amazon-linux-2/recommended"
}

module "autoscaling" {
  source  = "terraform-aws-modules/autoscaling/aws"
  version = "~> 6.5"

  name = var.general.name

  image_id      = jsondecode(data.aws_ssm_parameter.ecs_optimized_ami.value)["image_id"]
  instance_type = var.ecs.instance_type

  security_groups                 = [module.autoscaling_sg.security_group_id]
  user_data                       = base64encode(local.user_data)
  ignore_desired_capacity_changes = var.ecs_autoscaling.ignore_desired_capacity_changes

  create_iam_instance_profile = true
  iam_role_name               = var.ecs.name
  iam_role_description        = "ECS role for ${var.ecs.name} EC2 Instances."
  iam_role_policies = {
    AmazonEC2ContainerServiceforEC2Role = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role",
    AmazonSSMManagedInstanceCore        = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  }

  vpc_zone_identifier = module.vpc.private_subnets
  health_check_type   = var.ecs_autoscaling.health_check_type
  min_size            = var.ecs_autoscaling.min_size
  max_size            = var.ecs_autoscaling.max_size
  desired_capacity    = var.ecs_autoscaling.desired_capacity

  # https://github.com/hashicorp/terraform-provider-aws/issues/12582
  autoscaling_group_tags = {
    AmazonECSManaged = true
  }

  # Required for  managed_termination_protection = "ENABLED"
  protect_from_scale_in = var.ecs_autoscaling.protect_from_scale_in

  tags = var.tags

  # IMDSv2
  metadata_options = {
    http_tokens = "required"
  }
}

module "autoscaling_sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 4.0"

  name                = var.general.name
  description         = "Autoscaling group security group"
  vpc_id              = module.vpc.vpc_id
  ingress_cidr_blocks = [module.vpc.vpc_cidr_block]

  ingress_rules = var.ecs_autoscaling_sg.ingress_rules
  egress_rules  = var.ecs_autoscaling_sg.egress_rules

  tags = var.tags
}

################################################################################
# ECS Cloudwatch Alerts Module
################################################################################

module "cluster_alerts" {
  source                          = "../../modules/cluster_alerts"
  sns_topic_name_for_alerts       = var.sns_topic_name_for_alerts
  sns_email_for_cloudwatch_alerts = var.sns_email_for_cloudwatch_alerts
  cluster_name                    = var.ecs.name
  CPUReservation_threshold        = var.CPUReservation_threshold
  CPUUtilization_threshold        = var.CPUUtilization_threshold
  MemoryReservation_threshold     = var.MemoryReservation_threshold
  MemoryUtilization_threshold     = var.MemoryUtilization_threshold
  tags                            = var.tags
}

################################################################################
# ECR Repository
################################################################################

module "ecr" {
  source                                 = "terraform-aws-modules/ecr/aws"
  version                                = "1.6.0"
  repository_name                        = var.general.name
  registry_scan_type                     = "BASIC"
  repository_image_tag_mutability        = "IMMUTABLE"
  manage_registry_scanning_configuration = true
  create_lifecycle_policy                = false
  registry_scan_rules = [
    {
      scan_frequency = "SCAN_ON_PUSH"
      filter         = "*"
      filter_type    = "WILDCARD"
    }
  ]
}