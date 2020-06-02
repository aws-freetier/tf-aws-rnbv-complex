###
variable "subnet_ids" {
  description = "A list of subnet IDs to launch resources in"
  type        = list(string)
}

variable "cluster_name" {
  description = "The name to use for all the cluster resources"
  type        = string
}

variable "security_groups" {
  description = "A list of security group IDs to assign to the launch configuration"
  type        = list(string)
  default     = []
}

variable "instance_type" {
  description = "The type of EC2 Instances to run (e.g. t2.micro)"
  type        = string
}

variable "min_size" {
  description = "The minimum number of EC2 Instances in the ASG"
  type        = number
}

variable "max_size" {
  description = "The maximum number of EC2 Instances in the ASG"
  type        = number
}

variable "user_data" {
  description = "The user data to provide when launching the instance. Do not pass gzip-compressed data via this argument; see user_data_base64 instead."
  type        = string
  default     = null
}

variable "image_id" {
  description = "The EC2 image ID to launch"
  type        = string
  default     = ""
}

variable "target_group_atlantis_arn" {
  description = "The target for atlantis traffic"
  type        = string
}

variable "key_name" {
  description = "The name of a key pair"
  type        = string
}

variable "iam_instance_profile" {
  description = "The security instance profile"
  type        = string
}
