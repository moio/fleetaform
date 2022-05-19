# Fleetaform

Automated [fleet](https://fleet.rancher.io/) test environments.

Light on hardware, ready in minutes, and all you need is `docker`!

[![golangci-lint](https://github.com/moio/fleetaform/actions/workflows/golangci-lint.yml/badge.svg)](https://github.com/moio/fleetaform/actions/workflows/golangci-lint.yml)

## Rationale
Testing fleet end-to-end requires multiple Kubernetes clusters, which can take significant and hardware resources to set up.

Fleetaform automates the deployment of lightweight Kubernetes ([k3s](https://k3s.io/)) clusters wrapped in docker containers ([k3d](https://k3d.io)) for a less painful testing experience.

## Requirements
 - `docker`, `helm`, `kubectl`. Get them all in a nice package with [Rancher Desktop](https://rancherdesktop.io/)!
 - [k3d](https://k3d.io)
 - 4 GB of RAM and one CPU core (default - 3 downstream clusters)
   - 1 extra GB of RAM and 0.25 cores per additional downstream cluster

## Quick start

Install fleetaform from [releases](https://github.com/moio/fleetaform/releases). Then run:

```sh
fleetaform -n 3
```

and four containers will be created:
- one container wrapping a Kubernetes cluster. Here `fleet` is installed
- three containers wrapping three "downstream" Kubernetes clusters. Here `fleet-agent` is installed and registered against the main cluster
- one Docker network to connect the containers above

Feel free to use [k9s](https://k9scli.io/) to inspect results!

More options are described with the `--help` option.
