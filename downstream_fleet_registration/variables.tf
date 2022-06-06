variable "upstream_internal_hostname" {
  type = string
}
variable "upstream_internal_port" {
  type = number
}
variable "upstream_external_hostname" {
  type = string
}
variable "upstream_external_port" {
  type = string
}
variable "upstream_credentials" {
  type = object({host: string, client_certificate: string, client_key:string, cluster_ca_certificate:string})
}
variable "downstream_credentials" {
  type = object({host: string, client_certificate: string, client_key:string, cluster_ca_certificate:string})
}
variable "token" {
  type = string
  default = null
}
