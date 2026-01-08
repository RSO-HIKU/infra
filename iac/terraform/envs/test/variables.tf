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
  default = "1.33.5"
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

variable "function_cors_allowed_origins" {
  type        = list(string)
  description = "Allowed origins for the Function App CORS policy."
  default = [
    "https://portal.azure.com",
    "http://localhost:8081"
  ]
}

variable "dotnet_version" {
  type        = string
  description = "Dotnet runtime version for Azure Functions."
  default     = "v10.0"
}

variable "functions_worker_runtime" {
  type        = string
  description = "Azure Functions worker runtime for C#."
  default     = "dotnet-isolated"
}


variable "traefik_web_nodeport" {
  type    = number
  default = 31823
}

variable "traefik_websecure_nodeport" {
  type    = number
  default = 32368
}

variable "traefik_nodeport_nsg_rule_priority" {
  type    = number
  default = 510
}