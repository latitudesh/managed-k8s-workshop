# 1. Prerequisites

Install the following tools:

- [Docker](https://docs.docker.com/get-started/get-docker/): will be used to run every node in this workshop as a container, both the `mgmt` nodes and the tenant workers.
- [kubectl](https://kubernetes.io/docs/tasks/tools/): will be used to talk to both clusters, `mgmt` and `tenant-a`.
- [kind](https://kind.sigs.k8s.io/docs/user/quick-start/): will be used to create the `mgmt` cluster, with each node as a Docker container.
- [cloud-provider-kind](https://github.com/kubernetes-sigs/cloud-provider-kind): will be used to give `LoadBalancer` Services an IP, so the `tenant-a` API server gets an endpoint, like a cloud load balancer would.
- [Helm](https://helm.sh/docs/intro/install/): will be used to install cert-manager and Kamaji on `mgmt`.

Give Docker at least **4 CPUs, 8 GB of RAM and 20 GB of disk**. You'll run 5 Kubernetes nodes as containers: 3 for `mgmt` and 2 tenant workers.

!!! warning "Pause VPNs and security agents that inspect TLS"
    (Cloudflare WARP, Zscaler, Netskope and similar) for the duration of the workshop. They replace the certificates of the sites you visit with their own. Your machine trusts that certificate, but the Kubernetes nodes you'll run as containers don't, so they can't pull images. If you can't pause it, ask your IT team for help before the workshop.

--8<-- "vevox-checkpoint.md"

Tools in place? Next, [get the workshop files](02-workshop-files.md).
