terraform {
  required_providers {
    helm = {
      source = "hashicorp/helm"
      version = "2.5.1"
    }
  }
}

provider "helm" {
  alias = "downstream"
  kubernetes {
    host = var.downstream_credentials.host
    client_certificate = var.downstream_credentials.client_certificate
    client_key = var.downstream_credentials.client_key
    cluster_ca_certificate = var.downstream_credentials.cluster_ca_certificate
  }
}

resource "helm_release" "fleet_agent" {
  provider = helm.downstream
  name       = "fleet-agent"
  namespace = "fleet-system"
  create_namespace = true
  chart = "https://github.com/rancher/fleet/releases/download/v0.3.9/fleet-agent-0.3.9.tgz"

  set_sensitive {
    name  = "apiServerCA"
    value = var.upstream_credentials.cluster_ca_certificate
  }
  set {
    name  = "apiServerURL"
    value = "https://${var.upstream_internal_hostname}:${var.upstream_internal_port}"
  }
  set {
    name  = "clusterNamespace"
    value = "fleet-local"
  }
  set {
    name  = "systemRegistrationNamespace"
    value = "fleet-clusters-system"
  }
  set_sensitive {
    name  = "token"
    value = var.token
  }
}