variable "credentials" {
  type = object({
    internal_host : string, internal_port : number, external_host : string, external_port : number,
    kubeconfig_host : string, client_certificate : string, client_key : string, cluster_ca_certificate : string
  })
}

variable "crd_chart" {
  default = "https://github.com/rancher/fleet/releases/download/v0.3.9/fleet-crd-0.3.9.tgz"
}
variable "chart" {
  default = "https://github.com/rancher/fleet/releases/download/v0.3.9/fleet-0.3.9.tgz"
}
variable "image_repository" {
  default = "rancher/fleet"
}
variable "image_tag" {
  default = "v0.3.9"
}
variable "agent_image_repository" {
  default = "rancher/fleet-agent"
}
variable "agent_image_tag" {
  default = "v0.3.9"
}
