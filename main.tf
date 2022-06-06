module "k3d" {
  source = "./k3d"
}

module "bare_fleet" {
  source = "./bare_fleet"
  upstream_internal_hostname = module.k3d.upstream_internal_hostname
  upstream_internal_url = module.k3d.upstream_internal_url
  upstream_external_url = module.k3d.upstream_external_url
  upstream_credentials = module.k3d.upstream_credentials
  downstream_credentials = module.k3d.downstream_credentials
}

# Comment module above and uncomment below to deploy fleet as a rancher component

#module "fleet_on_rancher" {
#  source = "./fleet_on_rancher"
#  upstream_internal_hostname = module.k3d.upstream_internal_hostname
#  upstream_internal_url = module.k3d.upstream_internal_url
#  upstream_external_url = module.k3d.upstream_external_url
#  upstream_credentials = module.k3d.upstream_credentials
#  downstream_credentials = module.k3d.downstream_credentials
#}
