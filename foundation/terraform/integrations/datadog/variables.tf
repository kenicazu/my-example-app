variable "account" {
  description = "Generic parameters for the variable"
  type        = map(string)
  default = {
    region = "us-east-1"
  }
}

variable "datadog_integration_aws" {
  description = "Datadog integration variables"
  type        = map(string)
  default = {
    roleName           = "DatadogAWSIntegrationRole"
    cpuutilization     = "80"
    memory_utilization = "80"
  }
}

variable "sns_topic_name_for_alerts" {
  type     = string
  nullable = false
}

variable "cluster_name" {
  type     = string
  nullable = false
}

