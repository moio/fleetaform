terraform {
  required_providers {
    helm = {
      source = "hashicorp/helm"
      version = "2.5.1"
    }
    kubernetes = {
      source = "hashicorp/kubernetes"
      version = "2.11.0"
    }
  }
}

provider "kubernetes" {
  alias = "upstream"
  host = var.upstream_credentials.host
  client_certificate = var.upstream_credentials.client_certificate
  client_key = var.upstream_credentials.client_key
  cluster_ca_certificate = var.upstream_credentials.cluster_ca_certificate
}

provider "helm" {
  alias = "upstream"
  kubernetes {
    host = var.upstream_credentials.host
    client_certificate = var.upstream_credentials.client_certificate
    client_key = var.upstream_credentials.client_key
    cluster_ca_certificate = var.upstream_credentials.cluster_ca_certificate
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

resource "helm_release" "fleet_fleet_crd" {
  provider = helm.upstream
  name       = "fleet-crd"
  namespace = "fleet-system"
  create_namespace = true
  chart = "https://github.com/rancher/fleet/releases/download/v0.3.9/fleet-crd-0.3.9.tgz"
}

resource "helm_release" "fleet_fleet" {
  provider = helm.upstream
  depends_on = [helm_release.fleet_fleet_crd]
  name       = "fleet"
  namespace = "fleet-system"
  chart = "https://github.com/rancher/fleet/releases/download/v0.3.9/fleet-0.3.9.tgz"
}

resource "helm_release" "fleet_token" {
  provider = helm.upstream
  depends_on = [helm_release.fleet_fleet]
  name       = "fleet-token-creator"
  chart      = "./charts/fleet-token-creator"
  namespace = "fleet-local"
  create_namespace = true
  wait_for_jobs = true
}

data "kubernetes_secret" "downstream_values" {
  provider = kubernetes.upstream
  depends_on = [helm_release.fleet_token]
  metadata {
    namespace = "fleet-local"
    name = "fleet-token"
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
    value = var.upstream_internal_url
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
    value = yamldecode(data.kubernetes_secret.downstream_values.data.values).token
  }
}