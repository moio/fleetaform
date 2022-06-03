terraform {
  required_providers {
    random = {
      source = "hashicorp/random"
      version = "3.2.0"
    }
    helm = {
      source = "hashicorp/helm"
      version = "2.5.1"
    }
    rancher2 = {
      source = "rancher/rancher2"
      version = "1.23.0"
    }
  }
}

resource "random_password" "api_token_key" {
  length = 64
  special = false
}

provider "rancher2" {
  alias = "upstream"
  api_url    = var.upstream_external_url
  token_key = "token-fleetaform:${random_password.api_token_key.result}"
  insecure = true
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

resource "helm_release" "cert-manager" {
  provider = helm.upstream
  name       = "cert-manager"
  repository = "https://charts.jetstack.io"
  chart       = "cert-manager"
  namespace = "cert-manager"
  version = "1.8.0"
  create_namespace = true
  set {
      name  = "installCRDs"
      value = true
  }
}

resource "helm_release" "rancher" {
  provider = helm.upstream
  depends_on = [helm_release.cert-manager]
  name       = "rancher"
  repository = "https://releases.rancher.com/server-charts/latest"
  chart       = "rancher"
  namespace = "cattle-system"
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
    value = var.upstream_url
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
    value = var.upstream_hostname
  }
  set {
    name  = "replicas"
    value = 1
  }
}

resource "helm_release" "rancher_configurator" {
  provider = helm.upstream
  depends_on = [helm_release.rancher]
  name       = "rancher-configurator"
  chart      = "./workloads/rancher-configurator"

  set {
    name  = "tokenString"
    value = random_password.api_token_key.result
  }

  wait_for_jobs = true
}

resource "helm_release" "fleet_token_creator" {
  provider = helm.upstream
  depends_on = [helm_release.rancher_configurator]
  name       = "fleet-token-creator"
  chart      = "./workloads/fleet-token-creator"
  wait_for_jobs = true
}

resource "rancher2_cluster" "imported_downstream" {
  provider = rancher2.upstream
  depends_on = [helm_release.fleet_token_creator]
  name = "downstream"
}

resource "helm_release" "rancher_importer" {
  provider = helm.downstream
  depends_on = [rancher2_cluster.imported_downstream]
  name       = "rancher-importer"
  chart      = "./workloads/rancher-importer"

  set {
    name  = "manifestUrl"
    value = rancher2_cluster.imported_downstream.cluster_registration_token.0.manifest_url
  }
  set_sensitive {
    name  = "clientCertificate"
    value = base64encode(var.downstream_credentials.client_certificate)
  }
  set_sensitive {
    name  = "clientKey"
    value = base64encode(var.downstream_credentials.client_key)
  }
  set_sensitive {
    name  = "clusterCACertificate"
    value = base64encode(var.downstream_credentials.cluster_ca_certificate)
  }
}
