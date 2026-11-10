# 14. Run it on LKS (optional)

kind is great to learn, but everything runs on your laptop. Now let's do it with real infrastructure: an [LKS](https://www.latitude.sh/docs/lks) cluster as the management cluster, and a bare metal server as the worker node.

Nothing from the kind setup is needed here. If you haven't done the [clean-up](13-clean-up.md) yet, do it first: this step reuses the `kmgmt` and `kta` aliases and the `tenant-a.kubeconfig` file, and it's easier when only one `tenant-a` exists.

What's different from the kind setup:

- **Management cluster**: an LKS cluster with 3 worker nodes, instead of kind.
- **Load balancer**: LKS gives `LoadBalancer` Services a public Elastic IP, so there's no `cloud-provider-kind`.
- **Worker node**: an Ubuntu 24.04 bare metal server, instead of a Docker container.
- **Network**: the `tenant-a` API server is on the public internet, like on a real managed provider.

You need:

- An LKS cluster with 3 worker nodes.
- A Latitude.sh bare metal server running Ubuntu 24.04, that you can SSH into.
- `kubectl` and `helm` on your machine.

## 14.1 Management cluster on LKS

Grab the kubeconfig of your LKS cluster from the Latitude.sh dashboard and point the `kmgmt` alias to it. That way, every `kmgmt` command from the workshop works as is:
```sh
alias kmgmt='kubectl --kubeconfig /path/to/lks-cluster-kubeconfig.yaml'

kmgmt get nodes
```

Kamaji's etcd needs persistent volumes. Check that the cluster has a default StorageClass:
```sh
kmgmt get storageclass
```

- `latitude-block (default)`: the 3 `kamaji-etcd` replicas get their volumes from it.

Install cert-manager and Kamaji exactly as in [Install Helm packages](05-helm-packages.md), replacing `--kubeconfig mgmt.kubeconfig` with the path to your LKS kubeconfig. Then verify the DataStore:
```sh
kmgmt get datastores
```

## 14.2 Hosted control plane on LKS

The only change to `tenant-a` is the load balancer class. Take a look at [`manifests/tenant-a-lks.yaml`](https://github.com/latitudesh/managed-k8s-workshop/blob/main/manifests/tenant-a-lks.yaml):

- `networkProfile.loadBalancerClass: latitude.sh/elastic-ip`: LKS only gives an Elastic IP to `LoadBalancer` Services with this class. Without it, the Service stays `<pending>`.

Create the `tenant-a` control plane:
```sh
kmgmt apply -f manifests/tenant-a-lks.yaml
```

Watch it until it becomes `Ready`:
```sh
kmgmt -n tenant-a get tenantcontrolplane tenant-a -w
```

- `CONTROL-PLANE ENDPOINT`: now a public Elastic IP.

Get the kubeconfig and save the API server IP, as before:
```sh
kmgmt -n tenant-a get secret tenant-a-admin-kubeconfig \
  -o jsonpath='{.data.admin\.conf}' | base64 -d > tenant-a.kubeconfig

alias kta='kubectl --kubeconfig tenant-a.kubeconfig'

export TENANT_A_APISERVER_IP=$(kmgmt -n tenant-a get svc tenant-a \
  -o jsonpath='{.status.loadBalancer.ingress[0].ip}')

kta version
```

## 14.3 Prepare the worker node

Save the server's public IP:
```sh
export WORKER_IP=<your server IP>
```

SSH into the server and become root:
```sh
ssh ubuntu@$WORKER_IP

sudo -i
```

The remaining steps in this section run on the server.

Disable swap:
```sh
swapoff -a
sed -i '/ swap / s/^/#/' /etc/fstab
```

Load the kernel modules and set the sysctls Kubernetes networking needs:
```sh
cat <<EOF > /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

modprobe overlay
modprobe br_netfilter

cat <<EOF > /etc/sysctl.d/k8s.conf
net.ipv4.ip_forward = 1
net.bridge.bridge-nf-call-iptables = 1
net.bridge.bridge-nf-call-ip6tables = 1
EOF

sysctl --system
```

- `overlay`: the filesystem containerd uses for container images.
- `br_netfilter` and `bridge-nf-call-*`: let iptables see bridged Pod traffic.
- `ip_forward`: let the node route Pod traffic.

Install containerd and runc:
```sh
CONTAINERD_VERSION=2.4.2
RUNC_VERSION=1.5.2
CONTAINERD_TGZ=containerd-${CONTAINERD_VERSION}-linux-amd64.tar.gz
CONTAINERD_URL=https://github.com/containerd/containerd/releases/download
CONTAINERD_RAW=https://raw.githubusercontent.com/containerd/containerd/main
RUNC_URL=https://github.com/opencontainers/runc/releases/download

curl -fsSL $CONTAINERD_URL/v${CONTAINERD_VERSION}/$CONTAINERD_TGZ \
  | tar -xz -C /usr/local
curl -fsSL -o /etc/systemd/system/containerd.service \
  $CONTAINERD_RAW/containerd.service
curl -fsSL -o /usr/local/sbin/runc $RUNC_URL/v${RUNC_VERSION}/runc.amd64
chmod +x /usr/local/sbin/runc

mkdir -p /etc/containerd
containerd config default \
  | sed 's/SystemdCgroup = false/SystemdCgroup = true/' \
  > /etc/containerd/config.toml

systemctl daemon-reload
systemctl enable --now containerd
```

Verify containerd uses `systemd` cgroups, matching the `cgroupfs: systemd` kubelet setting in `tenant-a-lks.yaml`:
```sh
grep SystemdCgroup /etc/containerd/config.toml
```

```{ .text .no-copy title="Output" }
            SystemdCgroup = true
```

Install kubelet and kubeadm, the same version as the control plane:
```sh
apt-get update
apt-get install -y apt-transport-https ca-certificates curl gpg

mkdir -p /etc/apt/keyrings
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.36/deb/Release.key \
  | gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg]' \
  'https://pkgs.k8s.io/core:/stable:/v1.36/deb/ /' \
  > /etc/apt/sources.list.d/kubernetes.list

apt-get update
apt-get install -y kubelet=1.36.4-1.1 kubeadm=1.36.4-1.1
apt-mark hold kubelet kubeadm
```

- `apt-mark hold`: stop `apt upgrade` from upgrading Kubernetes behind your back.

Verify the server can reach the `tenant-a` API server. Replace the IP with your `TENANT_A_APISERVER_IP`:
```sh
curl -k https://<TENANT_A_APISERVER_IP>:6443
```

- `403 Forbidden`: good news, as before. The network path and TLS work.

## 14.4 Join the worker node

From your machine, copy the `tenant-a` kubeconfig to the server:
```sh
scp tenant-a.kubeconfig ubuntu@$WORKER_IP:/tmp/tenant.kubeconfig
```

On the server, as root, create the join command, run it, and delete the kubeconfig:
```sh
JOIN=$(kubeadm token create --print-join-command \
  --kubeconfig /tmp/tenant.kubeconfig)
$JOIN

rm /tmp/tenant.kubeconfig
```

Back on your machine, the node joins as `NotReady`, as before:
```sh
kta get nodes
```

Install Cilium exactly as in [Install a CNI](07-worker-node.md#72-install-a-cni), then wait for the node to become `Ready`:
```sh
kta get nodes -w
```

## 14.5 Next steps

Your hosted control plane now runs on LKS with a bare metal worker node. Now go on your own adventure! You might want to:

- [Run a workload](09-workload.md) and call its NodePort over SSH.
- Block the LKS nodes from reaching the kubelet port, like in [Simulate a managed Kubernetes network](08-provider-network.md), and watch `logs` and `exec` break.
- [Enable Konnectivity](10-konnectivity.md) to fix them.
- [Upgrade the control plane](11-upgrade.md#111-upgrade-the-control-plane) to `v1.37.0`.
- [Install Sveltos](12-sveltos.md) in the LKS cluster and let it install Cilium on the bare metal node.
- Create a `tenant-b` and run two hosted control planes on the same LKS cluster.

## 14.6 Clean up LKS

Delete `tenant-a`. This deletes its Service and releases the Elastic IP:
```sh
kmgmt delete -f manifests/tenant-a-lks.yaml
```

Reset the worker node:
```sh
ssh ubuntu@$WORKER_IP sudo kubeadm reset -f
```

Delete the LKS cluster and the server from the Latitude.sh dashboard if you don't need them anymore.

---

Then head to the [Wrap-up](wrap-up.md).
