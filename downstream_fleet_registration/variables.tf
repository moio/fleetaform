variable "upstream_credentials" {
  type = object({
    internal_host : string, internal_port : number, external_host : string, external_port : number,
    kubeconfig_host : string, client_certificate : string, client_key : string, cluster_ca_certificate : string
  })
}
variable "downstream_credentials" {
  type = object({ kubeconfig_host : string, client_certificate : string, client_key : string, cluster_ca_certificate : string })
}
variable "token" {
  type    = string
  default = null
}

variable "chart" {
  default = "https://github.com/rancher/fleet/releases/download/v0.3.9/fleet-agent-0.3.9.tgz"
}
variable "image_repository" {
  default = "rancher/fleet-agent"
}
variable "image_tag" {
  default = "v0.3.9"
}

variable "labels" {
  default = {
    "env" = "dev"
  }
}
