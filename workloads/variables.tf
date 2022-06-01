variable "upstream_hostname" {
  type = string
}
variable "upstream_port" {
  type = string
}
variable "upstream_url" {
  type = string
}
variable "upstream_external_url" {
  type = string
}
variable "upstream_credentials" {
  type = object({host: string, client_certificate: string, client_key:string, cluster_ca_certificate:string})
}
variable "downstream_credentials" {
  type = object({host: string, client_certificate: string, client_key:string, cluster_ca_certificate:string})
}
