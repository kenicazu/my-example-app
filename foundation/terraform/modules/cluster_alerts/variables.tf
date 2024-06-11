variable "sns_topic_name_for_alerts" {
  # Defines the SNS Topic Name that will receive the Cloudwatch alerts
  type     = string
  nullable = false
}

variable "sns_email_for_cloudwatch_alerts" {
  # Defines the Email account that will receive the Cloudwatch alerts
  type     = string
  nullable = false
}

variable "cluster_name" {
  # Defines the cluster name for Cloudwatch alerts names
  type     = string
  nullable = false
}

variable "CPUReservation_threshold" {
  # Defines the CPUReservation_threshold 
  type    = string
  default = 75
}

variable "CPUUtilization_threshold" {
  # Defines the CPUUtilization_threshold 
  type    = string
  default = 75
}

variable "MemoryReservation_threshold" {
  # Defines the MemoryReservation_threshold 
  type    = string
  default = 75
}

variable "MemoryUtilization_threshold" {
  # Defines the MemoryUtilization_threshold 
  type    = string
  default = 75
}


variable "tags" {
  # Defines tags 
  type     = map(string)
  nullable = false
}
