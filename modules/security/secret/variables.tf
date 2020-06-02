###
variable "region" {
  description = "Region in which to create the cluster and run Atlantis."
  type        = string
}

variable "secret_name" {
  description = "The name of secret's key in secrets manager"
  type        = string
}
