# 1. Prerequisites

Five tools, all free, on macOS or Linux. Install them one by one from the links, or all at once with the script below. Then run the check script and give Docker enough room.

## 1.1 The tools

- [Docker](https://docs.docker.com/get-started/get-docker/): will be used to run every node in this workshop as a container, both the `mgmt` nodes and the tenant workers.
- [kubectl](https://kubernetes.io/docs/tasks/tools/): will be used to talk to both clusters, `mgmt` and `tenant-a`.
- [kind](https://kind.sigs.k8s.io/docs/user/quick-start/): will be used to create the `mgmt` cluster, with each node as a Docker container.
- [cloud-provider-kind](https://github.com/kubernetes-sigs/cloud-provider-kind): will be used to give `LoadBalancer` Services an IP, so the `tenant-a` API server gets an endpoint, like a cloud load balancer would.
- [Helm](https://helm.sh/docs/intro/install/): will be used to install cert-manager and Kamaji on `mgmt`.

## 1.2 Install them all at once

On macOS or Linux, the install script does the five in one go:
```sh
REPO=https://raw.githubusercontent.com/latitudesh/managed-k8s-workshop/main
curl -fsSL $REPO/install.sh | bash
```

!!! warning "The install script needs `sudo` and changes your machine"
    It installs the tools with Homebrew on macOS. On Linux, it copies them to `/usr/local/bin` and installs Docker from Docker's own package repository. It skips tools already on your `PATH`, but it can still break tools you installed another way. If you're not sure, install the tools manually with the links above.

## 1.3 Check your setup

Whichever way you installed them, check that every tool is there and able to run:
```sh
REPO=https://raw.githubusercontent.com/latitudesh/managed-k8s-workshop/main
curl -fsSL $REPO/check.sh | bash
```

!!! tip "The check script is safe to run"
    It only runs read-only commands, like `kubectl version` and `docker info`. It doesn't install or change anything.

## 1.4 Give Docker room

You'll run 5 Kubernetes nodes as containers, 3 for `mgmt` and 2 tenant workers. Give Docker at least:

<div class="lat-stats lat-stats--three">
  <div class="lat-stat">
    <p class="lat-stat__big">4 CPUs</p>
    <p class="lat-stat__text">Five nodes, each with its own kubelet and container runtime.</p>
  </div>
  <div class="lat-stat">
    <p class="lat-stat__big">8 GB RAM</p>
    <p class="lat-stat__text">Three control planes' worth of Pods on <code>mgmt</code>, plus the workloads.</p>
  </div>
  <div class="lat-stat">
    <p class="lat-stat__big">20 GB disk</p>
    <p class="lat-stat__text">Node images, the images every node pulls, and etcd.</p>
  </div>
</div>

!!! warning "Pause VPNs and security agents that inspect TLS"
    (Cloudflare WARP, Zscaler, Netskope and similar) for the duration of the workshop. They replace the certificates of the sites you visit with their own. Your machine trusts that certificate, but the Kubernetes nodes you'll run as containers don't, so they can't pull images. If you can't pause it, ask your IT team for help before the workshop.

--8<-- "vevox-checkpoint.md"

Tools in place? Next, [get the workshop files](02-workshop-files.md).
