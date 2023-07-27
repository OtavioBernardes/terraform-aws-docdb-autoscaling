# 'Constants'
locals {
  region      = data.aws_region.current.name
  account_id  = data.aws_caller_identity.current.account_id
  output_path = "${path.module}/.files/init.zip"
}

variable "cluster_identifier" {
  type        = string
  description = "DocumentDB cluster identifier."
}

variable "name" {
  type        = string
  default     = "docdb-autoscaling"
  description = "Resources name."
}

variable "min_capacity" {
  type        = number
  default     = 0
  description = "The minimum capacity."

  # Idiot-proof
  validation {
    condition     = var.min_capacity >= 0
    error_message = "Minimum capacity cannot be lower than 0."
  }

  # Source: https://docs.aws.amazon.com/documentdb/latest/developerguide/how-it-works.html
  validation {
    condition     = var.min_capacity <= 15
    error_message = "DocumentDB does not allow more than 15 replica instances."
  }
}

variable "max_capacity" {
  type        = number
  default     = 15
  description = "The maximum capacity."

  # Source: https://docs.aws.amazon.com/documentdb/latest/developerguide/how-it-works.html
  validation {
    condition     = var.max_capacity <= 15
    error_message = "DocumentDB does not allow more than 15 replica instances."
  }
}

variable "scaledown_schedule" {
  type = string
  default = "rate(1 hour)"
}

variable "scaling_policy" {
  type = object({
    metric_name      = string
    target           = number
    scaledown_target = number
    statistic        = string
    cooldown         = number
    period           = number
  })
  description = "The auto-scaling policy."
  default = {
    metric_name      = "CPUUtilization"
    target           = 60
    scaledown_target = 20
    statistic        = "Average"
    cooldown         = 120
    period           = 3600
  }
}
