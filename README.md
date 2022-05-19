# Fleetaform

Automated [fleet](https://fleet.rancher.io/) test environments.

Light on hardware, ready in minutes, and all you need is `docker`!

[![golangci-lint](https://github.com/moio/fleetaform/actions/workflows/golangci-lint.yml/badge.svg)](https://github.com/moio/fleetaform/actions/workflows/golangci-lint.yml)

## Rationale
Testing fleet end-to-end requires multiple Kubernetes clusters, which can take significant and hardware resources to set up.

Fleetaform automates the deployment of lightweight Kubernetes ([k3s](https://k3s.io/)) wrapped in docker containers ([k3d](https://k3d.io)) for a less painful testing experience.

## Requirements
 - `docker`, `helm`, `kubectl`. Get them all in a nice package with [Rancher Desktop](https://rancherdesktop.io/)!
 - [k3d](https://k3d.io)
 - 4 GB of RAM and one CPU core (default - 3 downstream clusters)
   - 1 extra GB of RAM and 0.25 cores per additional downstream cluster
