terraform {
  required_providers {
    random = {
      source  = "hashicorp/random"
      version = "3.2.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "2.5.1"
    }
    rancher2 = {
      source  = "rancher/rancher2"
      version = "1.23.0"
    }
  }
}

resource "random_password" "api_token_key" {
  length  = 64
  special = false
}

provider "rancher2" {
  alias     = "upstream"
  api_url   = "https://${var.credentials.external_host}:${var.credentials.external_port}"
  token_key = "token-fleetaform:${random_password.api_token_key.result}"
  insecure  = true
}

provider "helm" {
  alias = "upstream"
  kubernetes {
    host                   = var.credentials.kubeconfig_host
    client_certificate     = var.credentials.client_certificate
    client_key             = var.credentials.client_key
    cluster_ca_certificate = var.credentials.cluster_ca_certificate
  }
}

resource "helm_release" "cert-manager" {
  provider         = helm.upstream
  name             = "cert-manager"
  repository       = "https://charts.jetstack.io"
  chart            = "cert-manager"
  namespace        = "cert-manager"
  version          = "1.8.0"
  create_namespace = true
  set {
    name  = "installCRDs"
    value = true
  }
}

resource "helm_release" "rancher" {
  provider         = helm.upstream
  depends_on       = [helm_release.cert-manager]
  name             = "rancher"
  repository       = "https://releases.rancher.com/server-charts/latest"
  chart            = "rancher"
  namespace        = "cattle-system"
  create_namespace = true

  set {
    name  = "bootstrapPassword"
    value = "admin"
  }
  set {
    name  = "extraEnv[0].name"
    value = "CATTLE_SERVER_URL"
  }
  set {
    name  = "extraEnv[0].value"
    value = "https://${var.credentials.internal_host}"
  }
  set {
    name  = "extraEnv[1].name"
    value = "CATTLE_BOOTSTRAP_PASSWORD"
  }
  set {
    name  = "extraEnv[1].value"
    value = "admin"
  }
  set {
    name  = "hostname"
    value = var.credentials.internal_host
  }
  set {
    name  = "replicas"
    value = 1
  }
}

resource "helm_release" "rancher_configurator" {
  provider   = helm.upstream
  depends_on = [helm_release.rancher]
  name       = "rancher-configurator"
  chart      = "./charts/rancher-configurator"

  set {
    name  = "tokenString"
    value = random_password.api_token_key.result
  }

  wait_for_jobs = true
}

resource "helm_release" "fleet_token_creator" {
  provider      = helm.upstream
  depends_on    = [helm_release.rancher_configurator]
  name          = "fleet-token-creator"
  chart         = "./charts/fleet-token-creator"
  wait_for_jobs = true
}

resource "rancher2_cluster" "imported_downstream" {
  count      = var.downstream_cluster_count
  provider   = rancher2.upstream
  depends_on = [helm_release.fleet_token_creator]
  name       = "downstream-${count.index}"
}

output "manifest_urls" {
  value = [
    for downstream in rancher2_cluster.imported_downstream : downstream.cluster_registration_token.0.manifest_url
  ]
}
