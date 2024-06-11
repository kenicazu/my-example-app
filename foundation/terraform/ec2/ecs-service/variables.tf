//TODO:remove default values. 
variable "name" {
  type        = string
  description = "service name"
  default     = "ecsdemo-backend"
}
variable "container_name" {
  type        = string
  default     = "ecsdemo-backend"
  description = "Demo container name"
}
variable "region" {
  type        = string
  default     = "us-east-1"
  description = "AWS deployment region"
}
variable "container_image" {
  type        = string
  default     = "public.ecr.aws/aws-containers/ecsdemo-nodejs:c3e96da"
  description = "Container image"
}
variable "container_port" {
  type        = number
  default     = 3000
  description = "Container port"
}
variable "capacity_provider_name" {
  type        = string
  default     = "core-infra"
  description = "Name of the capacity provider that the service will be using as base."
}
variable "enable_service_autoscaling" {
  type        = bool
  default     = true
  description = "Set to true to enable service autoscaling"
}
variable "create_iam_service_role" {
  type        = bool
  default     = false
  description = "Set to true to create iam service role"
}

variable "autoscaling_min_capacity" {
  type        = number
  default     = 2
  description = "Autoscaling Minimum Capacity"
}

variable "autoscaling_max_capacity" {
  type        = number
  default     = 6
  description = "Autoscaling Maximum Capacity"
}

variable "autoscaling_policy_target_tracking_memory_cpu" {
  type = map(any)
  default = {
    "cpu" : {
      "policy_type" : "TargetTrackingScaling",
      "target_tracking_scaling_policy_configuration" : {
        "predefined_metric_specification" : {
          "predefined_metric_type" : "ECSServiceAverageCPUUtilization"
        }
      }
    },
    "memory" : {
      "policy_type" : "TargetTrackingScaling",
      "target_tracking_scaling_policy_configuration" : {
        "predefined_metric_specification" : {
          "predefined_metric_type" : "ECSServiceAverageMemoryUtilization"
        }
      }
    }
  }
  description = "Autoscaling Policy Target Tracking"
}

variable "placement_strategy_spread_az_instance_id" {
  type = list(map(string))
  default = [
    {
      "field" : "attribute:ecs.availability-zone",
      "type" : "spread"
    },
    {
      "field" : "instanceId",
      "type" : "spread"
    }
  ]
}

variable "placement_strategy_spread_az_binpack_memory" {
  type = list(map(string))
  default = [
    {
      "field" : "attribute:ecs.availability-zone",
      "type" : "spread"
    },
    {
      "field" : "memory",
      "type" : "binpack"
    }
  ]
}

variable "placement_strategy_spread_az" {
  type = list(map(string))
  default = [
    {
      "field" : "attribute:ecs.availability-zone",
      "type" : "spread"
    }
  ]
}

variable "placement_strategy_spread_instance_id" {
  type = list(map(string))
  default = [
    {
      "field" : "instanceId",
      "type" : "spread"
    }
  ]
}

variable "placement_strategy_binpack_memory" {
  type = list(map(string))
  default = [
    {
      "field" : "memory",
      "type" : "binpack"
    }
  ]
}
variable "placement_strategy_random" {
  type = list(map(string))
  default = [
    {
      "type" : "random"
    }
  ]
}

# variable environment_variables {
#   type        = list(map)
#   default     = [
#         {
#           name  = "NODEJS_URL",
#           value = "http://ecsdemo-backend.${data.aws_service_discovery_dns_namespace.this.name}:3000"
#         }
#       ]
#   description = "Use to define environment variables for the task definition."
# }
