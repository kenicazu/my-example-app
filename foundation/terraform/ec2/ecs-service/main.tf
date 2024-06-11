provider "aws" {
  region = var.region
}

locals {
  tags = {
    Blueprint  = var.name
    GithubRepo = "github.com/aws-ia/ecs-blueprints"
  }
}

################################################################################
# ECS Blueprint
################################################################################

module "ecs_service" {
  source  = "terraform-aws-modules/ecs/aws//modules/service"
  version = "~> 5.0"

  name               = var.name
  desired_count      = 3
  cluster_arn        = data.aws_ecs_cluster.core_infra.arn
  enable_autoscaling = var.enable_service_autoscaling

  # Autoscaling examples on terraform.tfvars.example or use a custom strategy
  autoscaling_min_capacity = var.autoscaling_min_capacity
  autoscaling_max_capacity = var.autoscaling_max_capacity
  autoscaling_policies     = var.autoscaling_policy_target_tracking_memory_cpu

  # Placement strategies examples on terraform.tfvars.example or use a custom strategy
  ordered_placement_strategy = var.placement_strategy_spread_az_binpack_memory

  # Task Definition
  requires_compatibilities = ["EC2"]
  capacity_provider_strategy = {
    default = {
      capacity_provider = var.capacity_provider_name
      weight            = 1
      base              = 1
    }
  }
  #TODO  add capacity provider flexibility
  create_iam_role        = var.create_iam_service_role
  task_exec_iam_role_arn = one(data.aws_iam_roles.ecs_core_infra_exec_role.arns)
  enable_execute_command = true

  container_definitions = {
    (var.container_name) = {
      image                    = var.container_image
      readonly_root_filesystem = false
      port_mappings = [
        {
          name          = "${var.container_name}-${var.container_port}"
          protocol      = "tcp",
          containerPort = var.container_port
          hostPort      = var.container_port
        }
      ]

      environment = [
        {
          name  = "NODEJS_URL",
          value = "http://ecsdemo-backend.${data.aws_service_discovery_dns_namespace.this.name}:3000"
        }
      ]
    }
  }

  service_registries = {
    registry_arn = aws_service_discovery_service.this.arn
  }

  load_balancer = [
    {
      container_name   = var.container_name
      container_port   = var.container_port
      target_group_arn = element(module.service_alb.target_group_arns, 0)
    }
  ]

  subnet_ids = data.aws_subnets.private.ids
  security_group_rules = {
    alb_ingress = {
      type                     = "ingress"
      from_port                = var.container_port
      to_port                  = var.container_port
      protocol                 = "tcp"
      description              = "Service port"
      source_security_group_id = module.service_alb.security_group_id
    }
    # TODO limit egress rules
    egress_all = {
      type        = "egress"
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }

  tags = local.tags
}

resource "aws_service_discovery_service" "this" {
  name = var.name

  dns_config {
    namespace_id = data.aws_service_discovery_dns_namespace.this.id

    dns_records {
      ttl  = 10
      type = "A"
    }

    routing_policy = "MULTIVALUE"
  }

  health_check_custom_config {
    failure_threshold = 1
  }
}
#TODO does the service_alb is supposed to be inside the service module? This will imply 1 alb per service. 
module "service_alb" {
  source  = "terraform-aws-modules/alb/aws"
  version = "~> 8.3"

  name               = "${var.name}-alb"
  load_balancer_type = "application"

  vpc_id  = data.aws_vpc.vpc.id
  subnets = data.aws_subnets.public.ids
  security_group_rules = {
    ingress_all_http = {
      type        = "ingress"
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      description = "HTTP web traffic"
      cidr_blocks = ["0.0.0.0/0"]
    }
    egress_all = {
      type        = "egress"
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }

  http_tcp_listeners = [
    {
      port               = "80"
      protocol           = "HTTP"
      target_group_index = 0
    },
  ]

  target_groups = [
    {
      name             = "${var.name}-tg"
      backend_protocol = "HTTP"
      backend_port     = var.container_port
      target_type      = "ip"
      health_check = {
        path    = "/"
        port    = var.container_port
        matcher = "200-299"
      }
    },
  ]

  tags = local.tags
}

################################################################################
# Supporting Resources
################################################################################

data "aws_vpc" "vpc" {
  filter {
    name   = "tag:Name"
    values = ["ecs-core"]
  }
}

data "aws_subnets" "public" {
  filter {
    name   = "tag:Name"
    values = ["ecs-core-public-*"]
  }
}

data "aws_subnets" "private" {
  filter {
    name   = "tag:Name"
    values = ["ecs-core-private-*"]
  }
}

data "aws_subnet" "private_cidr" {
  for_each = toset(data.aws_subnets.private.ids)
  id       = each.value
}

data "aws_ecs_cluster" "core_infra" {
  cluster_name = "ecs-core"
}

data "aws_iam_roles" "ecs_core_infra_exec_role" {
  name_regex = "ecs-core-execution*"
}

data "aws_service_discovery_dns_namespace" "this" {
  name = "default.${data.aws_ecs_cluster.core_infra.cluster_name}.local"
  type = "DNS_PRIVATE"
}