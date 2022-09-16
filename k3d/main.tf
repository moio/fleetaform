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

  image   = var.k3s_image
  network = "k3d"

  k3d {
    disable_load_balancer     = true
  }

  kubeconfig {
    update_default_kubeconfig = true
    switch_current_context    = true
  }

  k3s {
    extra_args {
      // https://github.com/kubernetes/kubernetes/issues/104459
      arg          = "--disable=metrics-server"
    }
    extra_args {
      // override limit of 1000000 (kubelet's default)
      arg          = "--kubelet-arg=--max-open-files=67108864"
    }
  }

  dynamic "port" {
    for_each = merge({6443=443}, var.upstream_port_mappings)
    content {
      host_port      = port.key
      container_port = port.value
      node_filters = [
        "server:0:direct",
      ]
    }
  }
}

resource "k3d_cluster" "downstream" {
  count = var.downstream_clusters
  depends_on = [docker_network.shared_network]
  name    = "downstream-${count.index}"
  servers = 1
  agents  = 0

  image   = var.k3s_image
  network = "k3d"

  k3d {
    disable_load_balancer     = true
  }

  kubeconfig {
    update_default_kubeconfig = true
    switch_current_context    = false
  }

  // https://github.com/kubernetes/kubernetes/issues/104459
  k3s {
    extra_args {
      arg          = "--disable=metrics-server"
    }
  }
}

output "upstream_credentials" {
  value = {
    internal_host = "k3d-upstream-server-0"
    internal_port = 6443
    external_host = "rancher.local.gd"
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
