variable "downstream_clusters" {
  default = 1
}

variable "upstream_port_mappings" {
  description = "Host port to container port forwarding map (eg. to expose NodePort services externally)"
  default = {
    6443 = 443
  }
}

variable "k3s_image" {
  default = "docker.io/rancher/k3s:v1.23.6-k3s1"
}