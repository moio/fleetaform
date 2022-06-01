terraform {
  required_providers {
    random = {
      source = "hashicorp/random"
      version = "3.2.0"
    }
    local = {
      source = "hashicorp/local"
      version = "2.2.3"
    }
    http = {
      source = "terraform-aws-modules/http"
      version = "2.4.1"
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
    config_path = "~/.kube/config"
    config_context = "k3d-upstream"
  }
}

provider "helm" {
  alias = "downstream"
  kubernetes {
    config_path = "~/.kube/config"
    config_context = "k3d-downstream"
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

  wait = true
  wait_for_jobs = true
}

resource "helm_release" "api_token" {
  provider = helm.upstream
  depends_on = [helm_release.rancher]
  name       = "api-token-creator"
  chart      = "./workloads/api-token-creator"

  set {
    name  = "tokenString"
    value = random_password.api_token_key.result
  }
}

# HACK: Rancher's helm chart does not wait for the installation of fleet, specifically its CRDs
# waiting for them to be ready is necessary in order to instantiate the registration token
resource "null_resource" "wait_for_fleet" {
  depends_on = [helm_release.rancher]
  provisioner "local-exec" {
    command = <<EOT
for i in {1..100}
do
  kubectl wait --for condition=established crd/clusterregistrationtokens.fleet.cattle.io
  if [ $? -eq 0 ]
  then
      break
  fi
  sleep 3
done
EOT
  }
}

resource "helm_release" "fleet_token" {
  provider = helm.upstream
  depends_on = [null_resource.wait_for_fleet]
  name       = "fleet-token-creator"
  chart      = "./workloads/fleet-token-creator"
  namespace = "fleet-local"
  create_namespace = true
  wait_for_jobs = true
}

resource "rancher2_cluster" "imported_downstream" {
  provider = rancher2.upstream
  depends_on = [helm_release.api_token, helm_release.fleet_token]
  name = "downstream"
}

data "http" "import_manifest" {
  depends_on = [rancher2_cluster.imported_downstream]
  url = replace(rancher2_cluster.imported_downstream.cluster_registration_token.0.manifest_url, var.upstream_url, var.upstream_external_url)
  insecure = true
}

resource "local_file" "import_manifest" {
  filename = "./workloads/import-manifest/templates/manifest.yaml"
  content = data.http.import_manifest.body
}

resource "helm_release" "import_manifest" {
  provider = helm.downstream
  depends_on = [local_file.import_manifest]
  name       = "import-manifest"
  chart      = "./workloads/import-manifest"
}
