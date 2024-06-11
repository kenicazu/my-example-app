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

variable "repository_name" {
  type        = string
  description = "The repository name to use in CodePipeline source stage"
}

variable "dockerhub_secret_name" {
  type        = string
  description = "AWS Secrets Manager secret name for dockerhub credentials"
}