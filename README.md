# Fleetaform

Automated [fleet](https://fleet.rancher.io/) test environments.

Light on hardware, ready in minutes, and all you need is `terraform` and `docker`!

## Rationale
Testing fleet end-to-end requires multiple Kubernetes clusters, which can take significant and hardware resources to set up.

Fleetaform automates the deployment of lightweight Kubernetes ([k3s](https://k3s.io/)) clusters wrapped in docker containers ([k3d](https://k3d.io)) for a less painful testing experience.

## Requirements
 - `docker` ([Rancher Desktop](https://rancherdesktop.io/) recommended on non-Linux)
 - [terraform](https://www.terraform.io/downloads)
 - 4 GB of RAM and one CPU core (default - 3 downstream clusters)
   - 1 extra GB of RAM and 0.25 cores per additional downstream cluster

## Quick start

```
cd fleetaform
terraform init
terraform apply -auto-approve
```

That will create:
- one container wrapping a Kubernetes cluster. Here `fleet` is installed
- one container wrapping a "downstream" Kubernetes clusters. Here `fleet-agent` is installed and registered against the main cluster
- one Docker network to connect the containers above

Feel free to use [k9s](https://k9scli.io/) to inspect results!

### Install with Rancher

Edit `main.tf` commenting `upstream_fleet` and `downstream_fleet_registration` modules, and uncomment `upstream_rancher` and `downstream_rancher_registration` modules.

Once applied, the Rancher console will be accessible at:

[https://rancher.local.gd:6443](https://rancher.local.gd:6443)

### Other options

Edit `main.tf` according to comments to enable alternative setups.

### Quick operations

- Destroy everything: `terraform destroy -auto-approve`
- Hard destroy everything (if Terraform fails): `rm terraform.tfstate ; k3d cluster delete --all ; docker network rm k3d`
- Hard recreate everything from scratch:

```sh
rm terraform.tfstate ; k3d cluster delete --all ; docker network rm k3d ; terraform init; terraform apply -auto-approve
```
