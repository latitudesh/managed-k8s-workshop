# 11. Upgrade Kubernetes

Managed providers upgrade a cluster in two steps: the control plane first, then the worker nodes. The order matters. Kubernetes allows the kubelet to be older than the API server, but never newer (see the [version skew policy](https://kubernetes.io/releases/version-skew-policy/)).

## 11.1 Upgrade the control plane

In a second terminal, keep an eye on the `tenant-a` control plane Pods:
```sh
kmgmt -n tenant-a get pods -w
```

```{ .text .no-copy title="Output" }
NAME                       READY   STATUS    RESTARTS   AGE
tenant-a-9787c789c-thdlw   4/4     Running   0          6m28s
tenant-a-9787c789c-x8wvh   4/4     Running   0          6m28s
```

Patch the `TenantControlPlane` with a new Kubernetes version:
```sh
kmgmt -n tenant-a patch tenantcontrolplane tenant-a --type merge -p '{"spec":{"kubernetes":{"version":"v1.37.0"}}}'
```

```{ .text .no-copy title="Output" }
tenantcontrolplane.kamaji.clastix.io/tenant-a patched
```

Verify the `TenantControlPlane` resource status (`Upgrading` -> `Ready`):
```sh
kmgmt -n tenant-a get tenantcontrolplane tenant-a -w
```

```{ .text .no-copy title="Output" }
NAME       VERSION   INSTALLED VERSION   STATUS      CONTROL-PLANE ENDPOINT   KUBECONFIG                  DATASTORE   AGE
tenant-a   v1.37.0   v1.36.4             Upgrading   172.18.0.5:6443          tenant-a-admin-kubeconfig   default     4d14h
[...]
tenant-a   v1.37.0   v1.37.0             Ready       172.18.0.5:6443          tenant-a-admin-kubeconfig   default     4d14h
```

- `VERSION`: the version you asked for.
- `INSTALLED VERSION`: the version actually running. It catches up when the upgrade is done.

Meanwhile, in the second terminal, the Deployment rolls the control plane Pods:
```{ .text .no-copy title="Output" }
NAME                        READY   STATUS              RESTARTS   AGE
tenant-a-6c94fb5755-2fp22   0/4     ContainerCreating   0          0s
tenant-a-6c94fb5755-rqgnv   0/4     ContainerCreating   0          0s
[...]
tenant-a-6c94fb5755-2fp22   4/4     Running             0          31s
tenant-a-6c94fb5755-rqgnv   4/4     Running             0          31s
tenant-a-9787c789c-x8wvh    4/4     Terminating         0          7m2s
tenant-a-9787c789c-thdlw    4/4     Terminating         0          7m2s
```

- `tenant-a-6c94fb5755-*`: the new Pods, running `v1.37.0`.
- `tenant-a-9787c789c-*`: the old Pods keep serving until the new ones are ready, then terminate.

Verify, from `tenant-a`'s perspective, the new Kubernetes version:
```sh
kta version
```

```{ .text .no-copy title="Output" }
Client Version: v1.36.2
Kustomize Version: v5.8.1
Server Version: v1.37.0
```

And the worker node is still v1.36.4:
```sh
kta get node
```

```{ .text .no-copy title="Output" }
NAME                STATUS   ROLES    AGE   VERSION
tenant-a-worker-1   Ready    <none>   66m   v1.36.4
```

Our workload didn't notice anything:
```sh
kta get pods
```

```{ .text .no-copy title="Output" }
NAME                   READY   STATUS    RESTARTS   AGE
web-795767664d-c4xkh   1/1     Running   0          15m
web-795767664d-sl6tx   1/1     Running   0          15m
```

## 11.2 Upgrade the worker node

Managed providers usually don't upgrade nodes in place. They add a new node with the new version, move the workloads, and remove the old one. Every node starts from a clean image, and if something goes wrong, the old node is still there.

Add a new worker node with v1.37.0, the same way you joined the first one:
```sh
docker run -d --name tenant-a-worker-2 --hostname tenant-a-worker-2 --network kind --privileged --volume /var kindest/node:v1.37.0

docker cp tenant-a.kubeconfig tenant-a-worker-2:/root/tenant.kubeconfig

JOIN=$(docker exec tenant-a-worker-2 kubeadm token create --print-join-command --kubeconfig /root/tenant.kubeconfig)

docker exec tenant-a-worker-2 sh -c "$JOIN --ignore-preflight-errors=all"
```

Verify the new worker node arrived in the cluster:
```sh
kta get node -w
```

```{ .text .no-copy title="Output" }
NAME                STATUS   ROLES    AGE   VERSION
tenant-a-worker-1   Ready    <none>   4d    v1.36.4
tenant-a-worker-2   Ready    <none>   31s   v1.37.0
```

Cilium and the Konnectivity agent are DaemonSets, so they start on the new node automatically:
```sh
kta -n kube-system rollout status ds/cilium
kta -n kube-system rollout status ds/konnectivity-agent
```

```{ .text .no-copy title="Output" }
daemon set "cilium" successfully rolled out
daemon set "konnectivity-agent" successfully rolled out
```

Drain the old worker node:
```sh
kta drain tenant-a-worker-1 --ignore-daemonsets --delete-emptydir-data --force
```

```{ .text .no-copy title="Output" }
node/tenant-a-worker-1 cordoned
Warning: ignoring DaemonSet-managed Pods: kube-system/cilium-envoy-7vvsl, kube-system/cilium-q8cz2, kube-system/konnectivity-agent-lpfcj
evicting pod default/web-795767664d-sl6tx
evicting pod default/web-795767664d-c4xkh
[...]
node/tenant-a-worker-1 drained
```

- `drain`: cordons the node, so no new Pods get scheduled on it, then evicts its Pods. They get recreated on `tenant-a-worker-2`.
- `--ignore-daemonsets`: DaemonSet Pods (Cilium, Konnectivity agent) belong to their node, so skip them instead of failing.
- `--delete-emptydir-data`: allow evicting Pods with `emptyDir` volumes. That data is lost.
- `--force`: also evict Pods not managed by a controller. They won't be recreated.

Remove the old worker node:
```sh
kta delete node tenant-a-worker-1

docker rm -f tenant-a-worker-1
```

Verify everything runs on the new worker node:
```sh
kta get pods -A -o wide
```

```{ .text .no-copy title="Output" }
NAMESPACE     NAME                               READY   STATUS    RESTARTS   AGE    IP             NODE                NOMINATED NODE   READINESS GATES
default       web-795767664d-fs2jd               1/1     Running   0          63s    10.244.1.127   tenant-a-worker-2   <none>           <none>
default       web-795767664d-jzfb4               1/1     Running   0          63s    10.244.1.239   tenant-a-worker-2   <none>           <none>
kube-system   cilium-envoy-6kt8g                 1/1     Running   0          105s   172.18.0.7     tenant-a-worker-2   <none>           <none>
kube-system   cilium-operator-6647c45686-jgzzt   1/1     Running   0          63s    172.18.0.7     tenant-a-worker-2   <none>           <none>
kube-system   cilium-qdz2z                       1/1     Running   0          105s   172.18.0.7     tenant-a-worker-2   <none>           <none>
kube-system   coredns-695c5d47b8-9dglb           1/1     Running   0          63s    10.244.1.48    tenant-a-worker-2   <none>           <none>
kube-system   coredns-695c5d47b8-wx79f           1/1     Running   0          63s    10.244.1.80    tenant-a-worker-2   <none>           <none>
kube-system   konnectivity-agent-kq2wr           1/1     Running   0          69s    10.244.1.117   tenant-a-worker-2   <none>           <none>
```

The cluster is fully on `v1.37.0`, and the workload kept running the whole time.

One thing is still manual, though: the CNI you installed by hand in step 7. Next, [let the management cluster install it](12-sveltos.md).
