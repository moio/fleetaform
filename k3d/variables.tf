variable "downstream_clusters" {
  default = 1
}

variable "upstream_port_mappings" {
  description = "Host port to container port forwarding map (eg. to expose NodePort services externally)"
  default = {
    6443 = 443
  }
}
