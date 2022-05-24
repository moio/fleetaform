module "clusters" {
  source = "./clusters"
}

module "workloads" {
  source = "./workloads"
  fleet_ca_certificate = module.clusters.fleet_ca_certificate
  fleet_api_url = module.clusters.fleet_api_url
}
