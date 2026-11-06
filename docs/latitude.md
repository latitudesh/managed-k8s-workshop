# What is Latitude.sh?

[Latitude.sh](https://www.latitude.sh) is a bare metal cloud. You get dedicated, single-tenant servers with no hypervisor and no neighbors, and you deploy them the way you'd deploy a VM: from a dashboard, an API or Terraform, in seconds, in any of 26 locations across 5 continents.

Around the servers, the products you'd expect from a cloud:

| Product | What it is |
|---|---|
| **Metal** and **Metal GPU** | Dedicated servers, with and without GPUs, provisioned in under 5 seconds. |
| **LKS** (Latitude Kubernetes Service) | Managed Kubernetes on bare metal. The product this workshop takes apart. |
| **Virtual machines** | VMs, when you don't need a whole server. |
| **Object, block and file storage** | S3-compatible buckets, persistent volumes that attach to servers and outlive them, and shared filesystems. |
| **Managed Postgres** | Managed databases. |
| **Private networks, Elastic IPs, BYOIP, Firewall, DDoS protection** | The networking around the servers. An Elastic IP is a portable IPv4 address you move between servers or announce over BGP. |
| **Cloud Gateway** and **Global Gateway** | Private interconnection to other clouds and between Latitude.sh locations. |

Everything is automated behind the same API. You can drive it from the dashboard, the [`lsh` CLI](https://www.latitude.sh/docs/cli), the [Terraform provider](https://www.latitude.sh/docs/guides/terraform), the [TypeScript, Go and Python SDKs](https://www.latitude.sh/docs/client-libraries) or an MCP server. Full details are in the [docs](https://www.latitude.sh/docs).

Take a guided tour of the dashboard below.

<div class="arcade-embed">
<iframe src="https://demo.arcade.software/sjNPzHRssWtrJYV80sLQ?embed&embed_mobile=tab&embed_desktop=inline&squared=true&disable_border=true&show_copy_link=true&utm_content=/managed-k8s-workshop/latitude" title="Dashboard overview" referrerpolicy="no-referrer-when-downgrade" frameborder="0" loading="lazy" allowfullscreen allow="clipboard-write; autoplay"></iframe>
</div>

## LKS, the managed Kubernetes

[LKS](https://www.latitude.sh/docs/lks) (Latitude Kubernetes Service) is Latitude.sh's managed Kubernetes.

A managed Kubernetes service splits a cluster in two. The provider operates the control plane, that is, the API server, etcd, the scheduler and the controller manager. The customer operates the nodes, where the workloads actually run. You never see the control plane: you create a cluster, get a kubeconfig, add nodes, and start deploying.

In LKS the split works like this:

- **Control plane.** Latitude.sh runs the API server and etcd as a highly available control plane. You don't size, access or patch it. The cluster is upstream Kubernetes, so standard tooling works as is.
- **Nodes.** You run your workloads on node pools, which are groups of bare metal servers of the same plan. You pick the plan, the size, and the labels and taints.
- **Networking.** Cilium is the CNI. A `LoadBalancer` Service gets an Elastic IP announced over BGP. Load balancing is L4 only, so HTTP routing needs an Ingress or Gateway controller of your choice.
- **Storage.** A `PersistentVolumeClaim` gets a block storage volume that follows the Pod, or a file storage filesystem shared across nodes.
- **Upgrades.** Latitude.sh provides the node images and rolls them out through node pool upgrades. You decide when to move to a new Kubernetes version.

Each of those is something the workshop builds, or at least simulates. The [Introduction](index.md#how-this-maps-to-the-real-world) has the table of which piece is which.

!!! tip "Kamaji is one way to do it, not the way"
    The workshop uses Kamaji because it's open source and runs on a laptop. The point is the shape of the problem, a control plane in one network and nodes in another, not a specific implementation. Don't read the workshop as a blueprint of how LKS is built.

## Do you need an account?

Not for steps 1 to 13. Everything runs on your laptop in Docker.

[Step 14](14-lks.md) is the bonus round, with real infrastructure: an LKS cluster as the management cluster and a bare metal server as the worker node. For that you need a [Latitude.sh account](https://www.latitude.sh/dashboard/signup), an LKS cluster with 3 worker nodes and an Ubuntu 24.04 server. The step has its own clean-up section, so you can delete both when you're done.
