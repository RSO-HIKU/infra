variable "project" {
  type    = string
  default = "hiku"
}

variable "environment" {
  type    = string
  default = "test"
}

variable "location" {
  type    = string
  default = "polandcentral"
}

variable "location_short" {
  type    = string
  default = "plc"
}

variable "owner_tag" {
  type    = string
  default = "hiku-team"
}

variable "node_vm_size" {
  type    = string
  default = "Standard_B2s"
}

variable "node_count" {
  type    = number
  default = 1
}

variable "kubernetes_version" {
  type    = string
  default = "1.29"
}

variable "services" {
  type = map(object({
    db_user = string
    schema  = string
  }))
}

variable "terraform_runner_ip" {
  type = string
}