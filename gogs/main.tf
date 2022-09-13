terraform {
  required_providers {
    helm = {
      source  = "hashicorp/helm"
      version = "2.5.1"
    }
  }
}

provider "helm" {
  kubernetes {
    host                   = var.credentials.kubeconfig_host
    client_certificate     = var.credentials.client_certificate
    client_key             = var.credentials.client_key
    cluster_ca_certificate = var.credentials.cluster_ca_certificate
  }
}

resource "helm_release" "gogs" {
  name       = "gogs"
  namespace  = "gogs"
  create_namespace = true
  chart = "./charts/gogs-helm-chart"

  set {
    name  = "images.gogs"
    value = "gogs/gogs:0.12.3"
  }
  set {
    name  = "useInPodPostgres"
    value = "false"
  }
  set {
    name  = "dbType"
    value = "sqlite3"
  }
  set {
    name  = "externalDB.dbHost"
    value = "dontcare"
  }
  set {
    name  = "externalDB.dbPort"
    value = "5432"
  }
  set {
    name  = "externalDB.dbDatabase"
    value = "gogs"
  }
  set {
    name  = "externalDB.dbUser"
    value = "gogs"
  }
  set {
    name  = "externalDB.dbPassword"
    value = "gogs"
  }


  set {
    name  = "ingress.enabled"
    value = true
  }
  set {
    name  = "ingress.protocol"
    value = "https"
  }
  set {
    name  = "ingress.tls[0].secretName"
    value = "tls-rancher-ingress"
  }
  set {
    name  = "ingress.tls[0].hosts[0]"
    value = "gogs.local.gd"
  }
  set {
    name  = "service.http.externalHost"
    value = "gogs.local.gd"
  }
  set {
    name  = "service.http.externalPort"
    value = "6443"
  }

  set {
    name  = "extra_config"
    value = <<EOF

[server]
OFFLINE_MODE = true

[security]
INSTALL_LOCK = true

[auth]
ENABLE_REGISTRATION_CAPTCHA = false

EOF
  }
}
