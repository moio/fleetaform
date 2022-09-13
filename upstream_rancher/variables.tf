variable "credentials" {
  type = object({
    internal_host : string, internal_port : number, external_host : string, external_port : number,
    kubeconfig_host : string, client_certificate : string, client_key : string, cluster_ca_certificate : string
  })
}
variable "downstream_cluster_count" {
  type = number
}

variable "cert_manager_chart" {
  default = "https://charts.jetstack.io/charts/cert-manager-v1.8.0.tgz"
}

variable "chart" {
  default = "https://releases.rancher.com/server-charts/latest/rancher-2.6.5.tgz"
}

variable "image_repository" {
  default = "rancher/rancher"
}

variable "image_tag" {
  default = "v2.6.5"
}
