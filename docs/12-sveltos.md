# 12. Manage add-ons with Sveltos

So far you installed Cilium by hand: `helm install` from your laptop, with the admin kubeconfig, against one cluster. A provider runs hundreds of clusters and installs the same add-ons in all of them: the CNI, a CSI driver, metrics-server. Nobody runs `helm install` for each one. The management cluster has to do it.

[Project Sveltos](https://projectsveltos.io/) is a Kubernetes add-on controller for exactly this. It runs in `mgmt`, holds a kubeconfig for each tenant cluster, and installs Helm charts and manifests into every cluster that matches a label selector. You describe the add-ons once, and Sveltos pushes them to all matching clusters.

## 12.1 Install Sveltos

Install Sveltos in the management cluster:
```sh
helm upgrade --install projectsveltos projectsveltos/projectsveltos \
  --kubeconfig mgmt.kubeconfig \
  --namespace projectsveltos \
  --create-namespace \
  --version 1.17.0 \
  --set agent.managementCluster=true \
  --wait
```

- `agent.managementCluster=true`: Sveltos runs a small agent per managed cluster, to classify it and run health checks. By default it deploys the agent inside each managed cluster. This flag keeps the agents in `mgmt`, so nothing of the provider's runs in the customer's cluster.

Verify the Sveltos Pods:
```sh
kmgmt -n projectsveltos get pods
```

```{ .text .no-copy title="Output" }
NAME                                                  READY   STATUS    RESTARTS   AGE
access-manager-78fd55564-xh7zz                        1/1     Running   0          74s
addon-controller-66f6794688-2f89d                     1/1     Running   0          74s
classifier-manager-85694b7d48-c9rfz                   1/1     Running   0          73s
event-manager-74686dc998-knwqb                        1/1     Running   0          73s
hc-manager-66f5c47879-hr58l                           1/1     Running   0          74s
mcp-server-6947bf5467-njp76                           1/1     Running   0          73s
sc-manager-f657d9bc9-kcqxn                            1/1     Running   0          74s
shard-controller-8c5d75cf6-jvhb8                      1/1     Running   0          74s
sveltos-agent-80blpcdud783g9s9ugwi-77776c6975-bl56n   1/1     Running   0          42s
techsupport-controller-65b78994df-dx8vm               1/1     Running   0          73s
```

- `addon-controller`: the one we care about. It reads `ClusterProfile`s and runs Helm against the tenant clusters.
- `sc-manager`: watches `SveltosCluster`s and checks it can reach their API server.
- `classifier-manager` and `sveltos-agent-*`: classify managed clusters (for example, by Kubernetes version). One agent per cluster, kept in `mgmt` by the flag above.
- `access-manager`, `event-manager`, `hc-manager`, `shard-controller`, `techsupport-controller`, `mcp-server`: features we don't use in this workshop.

Sveltos also registered the management cluster itself:
```sh
kmgmt get sveltoscluster -A
```

```{ .text .no-copy title="Output" }
NAMESPACE   NAME   READY   VERSION   AGE   SHARD
mgmt        mgmt   true    v1.36.4   43s
```

- `mgmt`: a `SveltosCluster` for the management cluster, so you can manage add-ons in `mgmt` the same way. We'll leave it alone.

## 12.2 Register tenant-a

Sveltos needs to know `tenant-a` exists and how to reach it. That's a `SveltosCluster` resource pointing to a Secret with a kubeconfig. Kamaji already created that Secret: `tenant-a-admin-kubeconfig`, and its `admin.svc` key points to the in-cluster Service, exactly what a tool running inside `mgmt` needs.

Take a look at [`manifests/sveltos-tenant-a.yaml`](https://github.com/latitudesh/managed-k8s-workshop/blob/main/manifests/sveltos-tenant-a.yaml), each field is commented.

Register `tenant-a`:
```sh
kmgmt apply -f manifests/sveltos-tenant-a.yaml
```

```{ .text .no-copy title="Output" }
sveltoscluster.lib.projectsveltos.io/tenant-a created
```

Verify Sveltos can reach it:
```sh
kmgmt get sveltoscluster -A
```

```{ .text .no-copy title="Output" }
NAMESPACE   NAME       READY   VERSION   AGE   SHARD
mgmt        mgmt       true    v1.36.4   63s
tenant-a    tenant-a   true    v1.37.0   20s
```

- `READY`: Sveltos connected to the `tenant-a` API server with the kubeconfig from the Secret.
- `VERSION`: the Kubernetes version it found there.

!!! tip "Shortcut alert"
    The admin kubeconfig makes Sveltos cluster-admin in `tenant-a`. A provider would give its add-on manager its own identity, with only the permissions it needs.

Nothing landed in `tenant-a`:
```sh
kta get ns
```

```{ .text .no-copy title="Output" }
NAME              STATUS   AGE
cilium-secrets    Active   3m19s
default           Active   12d
kube-node-lease   Active   12d
kube-public       Active   12d
kube-system       Active   12d
```

- No `projectsveltos` namespace: Sveltos only talks to the API server, like you do with `kubectl`.
- `cilium-secrets`: Cilium's own namespace, from the manual install.

## 12.3 Uninstall Cilium by hand

Cilium is still the one you installed by hand. Remove it, so Sveltos can own it:
```sh
helm uninstall cilium --kubeconfig tenant-a.kubeconfig --namespace kube-system
```

```{ .text .no-copy title="Output" }
release "cilium" uninstalled
```

The Cilium Pods are gone:
```sh
kta get pods -A
```

```{ .text .no-copy title="Output" }
NAMESPACE     NAME                       READY   STATUS    RESTARTS   AGE
default       web-795767664d-lq6bc       1/1     Running   0          7d22h
default       web-795767664d-sz58f       1/1     Running   0          7d22h
kube-system   coredns-695c5d47b8-cd99k   1/1     Running   0          7d22h
kube-system   coredns-695c5d47b8-mp8g6   1/1     Running   0          7d22h
kube-system   konnectivity-agent-kq2wr   1/1     Running   0          7d23h
```

- The other Pods keep running: their network was wired up when they started, and the kernel keeps it. New Pods would not start.

But the node still says `Ready`:
```sh
kta get nodes
```

```{ .text .no-copy title="Output" }
NAME                STATUS   ROLES    AGE     VERSION
tenant-a-worker-2   Ready    <none>   7d23h   v1.37.0
```

Helm removed Cilium's Pods, but not the CNI config file the Cilium agent wrote on the node. containerd reads that file and tells the kubelet the network is ready. Remove it, to put the node back where it was before [Install a CNI](07-worker-node.md#72-install-a-cni):
```sh
docker exec tenant-a-worker-2 rm /etc/cni/net.d/05-cilium.conflist
```

The node goes `NotReady`, for the same reason as before:
```sh
kta get nodes -w
```

```{ .text .no-copy title="Output" }
NAME                STATUS     ROLES    AGE     VERSION
tenant-a-worker-2   NotReady   <none>   7d23h   v1.37.0
```

```sh
kta get node tenant-a-worker-2 \
  -o jsonpath='{.status.conditions[?(@.type=="Ready")].message}'
```

```{ .text .no-copy title="Output" }
container runtime network not ready: NetworkReady=false reason:NetworkPluginNotReady message:Network plugin returns error: cni plugin not initialized
```

## 12.4 Install Cilium with Sveltos

A `ClusterProfile` says which clusters (a label selector) get what (Helm charts, manifests). Take a look at [`manifests/sveltos-cilium.yaml`](https://github.com/latitudesh/managed-k8s-workshop/blob/main/manifests/sveltos-cilium.yaml): it's the same chart, version and values as the manual install, each field commented.

The only value that changes from one cluster to another is the API server IP. Replace the placeholder with yours and apply:
```sh
sed "s/TENANT_A_APISERVER_IP/$TENANT_A_APISERVER_IP/" \
  manifests/sveltos-cilium.yaml | kmgmt apply -f -
```

```{ .text .no-copy title="Output" }
clusterprofile.config.projectsveltos.io/cilium created
```

Sveltos matched the profile to `tenant-a` through the `cni: cilium` label:
```sh
kmgmt get clusterprofile cilium \
  -o jsonpath='{.status.matchingClusters[*].name}'
```

```{ .text .no-copy title="Output" }
tenant-a
```

For each matching cluster, Sveltos creates a `ClusterSummary`: the state of that profile on that cluster. Watch it:
```sh
kmgmt -n tenant-a get clustersummary -o wide -w
```

```{ .text .no-copy title="Output" }
NAME                      AGE   HELMCHARTS     KUSTOMIZEREFS   POLICYREFS
cilium-sveltos-tenant-a   6s    Provisioning
cilium-sveltos-tenant-a   10s   Provisioned
```

- `HELMCHARTS`: `Provisioning` while Sveltos runs the Helm install in `tenant-a`, then `Provisioned`.

Back in `tenant-a`, the node is `Ready` again:
```sh
kta get nodes
```

```{ .text .no-copy title="Output" }
NAME                STATUS   ROLES    AGE     VERSION
tenant-a-worker-2   Ready    <none>   7d23h   v1.37.0
```

And the Cilium Pods are back:
```sh
kta -n kube-system get pods
```

```{ .text .no-copy title="Output" }
NAME                               READY   STATUS    RESTARTS   AGE
cilium-bxtft                       1/1     Running   0          44s
cilium-envoy-wk6st                 1/1     Running   0          44s
cilium-operator-7bcf667cdb-mbp6l   1/1     Running   0          44s
coredns-695c5d47b8-cd99k           1/1     Running   0          7d22h
coredns-695c5d47b8-mp8g6           1/1     Running   0          7d22h
konnectivity-agent-kq2wr           1/1     Running   0          7d23h
```

It's still Helm. Sveltos ran the same install, from `mgmt`, with the kubeconfig Kamaji generated:
```sh
helm list --kubeconfig tenant-a.kubeconfig -A
```

```{ .text .no-copy title="Output" }
NAME  	NAMESPACE  	REVISION	UPDATED                               	STATUS  	CHART        	APP VERSION
cilium	kube-system	1       	2026-11-04 13:08:34.48236522 +0000 UTC	deployed	cilium-1.20.2	1.20.2
```

!!! tip "This is how the CNI is already there when you create a cluster"
    A provider labels every new cluster and registers it with its add-on manager. A profile like this one matches it right away, before the first node joins. By the time you download the kubeconfig, the CNI, the CSI driver and the rest are already installed, and you never ran `helm install`.

That's the whole provider: hosted control planes, a network boundary with a tunnel through it, upgrades, and add-ons pushed from `mgmt`. Next, [clean up](13-clean-up.md).
