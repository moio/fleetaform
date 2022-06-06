variable "upstream_credentials" {
  type = object({
    internal_host : string, internal_port : number, external_host : string, external_port : number,
    kubeconfig_host : string, client_certificate : string, client_key : string, cluster_ca_certificate : string
  })
}
variable "downstream_credentials" {
  type = object({ kubeconfig_host : string, client_certificate : string, client_key : string, cluster_ca_certificate : string })
}
variable "manifest_url" {
  type = string
}
