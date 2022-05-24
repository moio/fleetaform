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
terraform apply -target=module.clusters -auto-approve
terraform apply -auto-approve
```

That will create:
- one container wrapping a Kubernetes cluster. Here `fleet` is installed
- one container wrapping a "downstream" Kubernetes clusters. Here `fleet-agent` is installed and registered against the main cluster
- one Docker network to connect the containers above

Feel free to use [k9s](https://k9scli.io/) to inspect results!

### Cleaning up

``
terraform destroy -target=module.workloads -auto-approve
terraform destroy -auto-approve
``
