variable "account_id" {
  description = "An account ID that own AMIS"
  default     = ""
  type        = string
}

variable "cron" {
  description = "A cron style entry to dictate when the job runs. Default is 0 9 * * 2 which is every Tuesday at 9am"
  default     = "0 9 * * 2"
  type        = string
}

variable "delete_older_than_days" {
  description = "Delete an AMI created after this amount of days"
  default     = 60
  type        = number
}

variable "exclusion_tag" {
  description = "AMI Tag to check to exclude from deletion"
  default     = "DoNotDelete"
  type        = string
}

variable "filter_tag" {
  description = "A tag to filter the AMIs on"
  default     = ""
  type        = string
}

variable "prefix" {
  description = "A prefix for all the resources"
  type        = string
}
