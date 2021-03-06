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
  name = "k3d"
  driver = "bridge"
}

resource "k3d_cluster" "upstream" {
  depends_on = [docker_network.shared_network]
  name    = "upstream"
  servers = 1
  agents  = 0

  image   = "docker.io/rancher/k3s:v1.23.6-k3s1"
  network = "k3d"

  k3d {
    disable_load_balancer     = true
  }

  kubeconfig {
    update_default_kubeconfig = true
    switch_current_context    = true
  }

  port {
    host_port      = 6443
    container_port = 443
    node_filters = [
      "server:0:direct",
    ]
  }
}

resource "k3d_cluster" "downstream" {
  count = var.downstream_clusters
  depends_on = [docker_network.shared_network]
  name    = "downstream-${count.index}"
  servers = 1
  agents  = 0

  image   = "docker.io/rancher/k3s:v1.23.6-k3s1"
  network = "k3d"

  k3d {
    disable_load_balancer     = true
  }

  kubeconfig {
    update_default_kubeconfig = true
    switch_current_context    = false
  }
}

output "upstream_credentials" {
  value = {
    internal_host = "k3d-upstream-server-0"
    internal_port = 6443
    external_host = "localhost"
    external_port = 6443
    kubeconfig_host = k3d_cluster.upstream.credentials.0.host
    client_certificate = k3d_cluster.upstream.credentials.0.client_certificate
    client_key = k3d_cluster.upstream.credentials.0.client_key
    cluster_ca_certificate = k3d_cluster.upstream.credentials.0.cluster_ca_certificate
  }
}

output "downstream_credentials" {
  value = [
    for downstream in k3d_cluster.downstream : {
      kubeconfig_host = downstream.credentials.0.host
      client_certificate = downstream.credentials.0.client_certificate
      client_key = downstream.credentials.0.client_key
      cluster_ca_certificate = downstream.credentials.0.cluster_ca_certificate
    }
  ]
}
