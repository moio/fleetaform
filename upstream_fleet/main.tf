terraform {
  required_providers {
    helm = {
      source  = "hashicorp/helm"
      version = "2.5.1"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.11.0"
    }
  }
}

provider "kubernetes" {
  alias                  = "upstream"
  host                   = var.credentials.kubeconfig_host
  client_certificate     = var.credentials.client_certificate
  client_key             = var.credentials.client_key
  cluster_ca_certificate = var.credentials.cluster_ca_certificate
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

resource "helm_release" "fleet_fleet_crd" {
  provider         = helm.upstream
  name             = "fleet-crd"
  namespace        = "fleet-system"
  create_namespace = true
  chart            = var.crd_chart
}

resource "helm_release" "fleet_fleet" {
  provider   = helm.upstream
  depends_on = [helm_release.fleet_fleet_crd]
  name       = "fleet"
  namespace  = "fleet-system"
  chart            = var.chart

  set {
    name  = "image.repository"
    value = var.image_repository
  }
  set {
    name  = "image.tag"
    value = var.image_tag
  }
  set {
    name  = "agentImage.repository"
    value = var.agent_image_repository
  }
  set {
    name  = "agentImage.tag"
    value = var.agent_image_tag
  }
}

resource "helm_release" "fleet_token" {
  provider         = helm.upstream
  depends_on       = [helm_release.fleet_fleet]
  name             = "fleet-token-creator"
  chart            = "./charts/fleet-token-creator"
  namespace        = "fleet-local"
  create_namespace = true
  wait_for_jobs    = true
}

data "kubernetes_secret" "downstream_values" {
  provider   = kubernetes.upstream
  depends_on = [helm_release.fleet_token]
  metadata {
    namespace = "fleet-local"
    name      = "fleet-token"
  }
}

output "token" {
  value     = yamldecode(data.kubernetes_secret.downstream_values.data.values).token
  sensitive = true
}
