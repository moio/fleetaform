module "clusters" {
  source = "./clusters"
}

module "workloads" {
  source = "./workloads"
  upstream_hostname = module.clusters.upstream_hostname
  upstream_port = module.clusters.upstream_port
  upstream_url = module.clusters.upstream_url
  upstream_external_url = module.clusters.upstream_external_url
}
