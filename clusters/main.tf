terraform {
  required_providers {
    docker = {
      source = "kreuzwerker/docker"
      version = "2.16.0"
    }
    k3d = {
      source = "pvotal-tech/k3d"
      version = "0.0.6"
    }
  }
}

provider "docker" {
  host = "unix:///var/run/docker.sock"
}

resource "docker_network" "shared_network" {
  name = "fleet-network"
  driver = "bridge"
}

resource "k3d_cluster" "fleet" {
  depends_on = [docker_network.shared_network]
  name    = "fleet"
  servers = 1
  agents  = 0

  image   = "docker.io/rancher/k3s:v1.23.6-k3s1"
  network = "fleet-network"

  k3d {
    disable_load_balancer     = true
  }

  kubeconfig {
    update_default_kubeconfig = true
    switch_current_context    = true
  }
}

resource "k3d_cluster" "downstream" {
  depends_on = [docker_network.shared_network]
  name    = "downstream"
  servers = 1
  agents  = 0

  image   = "docker.io/rancher/k3s:v1.23.6-k3s1"
  network = "fleet-network"

  k3d {
    disable_load_balancer     = true
  }

  kubeconfig {
    update_default_kubeconfig = true
    switch_current_context    = false
  }
}

output "fleet_api_url" {
  value = "https://k3d-${k3d_cluster.fleet.name}-server-0:6443"
}

output "fleet_ca_certificate" {
  value = k3d_cluster.fleet.credentials.0.cluster_ca_certificate
}
