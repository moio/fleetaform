terraform {
  required_providers {
    helm = {
      source  = "hashicorp/helm"
      version = "2.5.1"
    }
  }
}

provider "helm" {
  alias = "downstream"
  kubernetes {
    host                   = var.downstream_credentials.kubeconfig_host
    client_certificate     = var.downstream_credentials.client_certificate
    client_key             = var.downstream_credentials.client_key
    cluster_ca_certificate = var.downstream_credentials.cluster_ca_certificate
  }
}

resource "helm_release" "fleet_agent" {
  provider         = helm.downstream
  name             = "fleet-agent"
  namespace        = "fleet-system"
  create_namespace = true
  chart            = var.chart

  set {
    name  = "image.repository"
    value = var.image_repository
  }
  set {
    name  = "image.tag"
    value = var.image_tag
  }
  set_sensitive {
    name  = "apiServerCA"
    value = var.upstream_credentials.cluster_ca_certificate
  }
  set {
    name  = "apiServerURL"
    value = "https://${var.upstream_credentials.internal_host}:${var.upstream_credentials.internal_port}"
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

  dynamic "set" {
    for_each = var.labels
    content {
      name = "labels.${set.key}"
      value = set.value
    }
  }
}
