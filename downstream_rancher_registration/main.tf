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

resource "helm_release" "rancher_importer" {
  provider = helm.downstream
  name       = "rancher-importer"
  chart      = "./charts/rancher-importer"

  set {
    name  = "manifestUrl"
    value = var.manifest_url
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
