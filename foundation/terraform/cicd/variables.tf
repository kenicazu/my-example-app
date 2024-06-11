variable "account" {
  description = "Generic parameters for the variable"
  type        = map(string)
  default = {
    region = "us-east-1"
  }
}

variable "ecr_repository_name" {
  type        = string
  description = "The ECR repository name for the app"
}

#variable "task_role_arn" {
#  type        = string
#  description = "The ECS task role ARN"
#}
#
#variable "task_execution_role_arn" {
#  type        = string
#  description = "The ECS task execution role ARN"
#}
#
#variable "capacity_provider" {
#  type        = string
#  description = "The ECS capacity provider name"
#}
#
#variable "capacity_provider_base" {
#  type        = string
#  description = "The ECS capacity provider base value"
#}
#
#variable "capacity_provider_weight" {
#  type        = string
#  description = "The ECS capacity provider weight value"
#}

variable "cluster_name" {
  type        = string
  description = "The ECS cluster name"
}

variable "container_name" {
  type        = string
  description = "The ECS service main container name"
}

variable "service_name" {
  type        = string
  description = "The ECS service name"
}