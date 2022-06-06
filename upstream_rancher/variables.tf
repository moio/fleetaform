variable "upstream_internal_hostname" {
  type = string
}
variable "upstream_internal_url" {
  type = string
}
variable "upstream_external_url" {
  type = string
}
variable "upstream_credentials" {
  type = object({host: string, client_certificate: string, client_key:string, cluster_ca_certificate:string})
}
variable "downstream_cluster_count" {
  type = number
}
