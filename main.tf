module "k3d" {
  source = "./k3d"
## Uncomment here and the downstream_fleet_registration_1 module below for multiple downstream clusters
#  downstream_clusters = 2
}

module "upstream_fleet" {
  source = "./upstream_fleet"
  upstream_internal_hostname = module.k3d.upstream_internal_hostname
  upstream_internal_port = module.k3d.upstream_internal_port
  upstream_external_url = module.k3d.upstream_external_url
  upstream_credentials = module.k3d.upstream_credentials
}

module "downstream_fleet_registration_0" {
  source = "./downstream_fleet_registration"
  upstream_internal_hostname = module.k3d.upstream_internal_hostname
  upstream_internal_port = module.k3d.upstream_internal_port
  upstream_external_url = module.k3d.upstream_external_url
  upstream_credentials = module.k3d.upstream_credentials
  downstream_credentials = module.k3d.downstream_credentials.0
  token = module.upstream_fleet.token
}

#module "downstream_fleet_registration_1" {
#  source = "./downstream_fleet_registration"
#  upstream_internal_hostname = module.k3d.upstream_internal_hostname
#  upstream_internal_port = module.k3d.upstream_internal_port
#  upstream_external_url = module.k3d.upstream_external_url
#  upstream_credentials = module.k3d.upstream_credentials
#  downstream_credentials = module.k3d.downstream_credentials.1
#  token = module.upstream_fleet.token
#}



## Comment all modules above and uncomment below to deploy fleet as a rancher component
#
#module "upstream_rancher" {
#  source = "./upstream_rancher"
#  upstream_internal_hostname = module.k3d.upstream_internal_hostname
#  upstream_internal_port = module.k3d.upstream_internal_port
#  upstream_external_url = module.k3d.upstream_external_url
#  upstream_credentials = module.k3d.upstream_credentials
#  downstream_cluster_count = 2
#}
#
#module "downstream_rancher_registration_0" {
#  source = "./downstream_rancher_registration"
#  upstream_internal_hostname = module.k3d.upstream_internal_hostname
#  upstream_internal_port = module.k3d.upstream_internal_port
#  upstream_external_url = module.k3d.upstream_external_url
#  upstream_credentials = module.k3d.upstream_credentials
#  downstream_credentials = module.k3d.downstream_credentials.0
#  manifest_url = module.upstream_rancher.manifest_urls.0
#}
#
#module "downstream_rancher_registration_1" {
#  source = "./downstream_rancher_registration"
#  upstream_internal_hostname = module.k3d.upstream_internal_hostname
#  upstream_internal_port = module.k3d.upstream_internal_port
#  upstream_external_url = module.k3d.upstream_external_url
#  upstream_credentials = module.k3d.upstream_credentials
#  downstream_credentials = module.k3d.downstream_credentials.1
#  manifest_url = module.upstream_rancher.manifest_urls.1
#}
