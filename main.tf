module "clusters" {
  source = "./clusters"
}

module "workloads" {
  source = "./workloads"
  upstream_ca_certificate = module.clusters.upstream_ca_certificate
  upstream_api_url = module.clusters.upstream_api_url
}
