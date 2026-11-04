# 3. Create the kind cluster (mgmt)

This is the provider's **management cluster**. Customers never see it, and it hosts their control planes. It has 1 control plane node and 2 workers, which gives the tenant control plane Pods and the etcd datastore room to spread out, like a small provider fleet.

Create the kind cluster:
```sh
kind create cluster --config manifests/kind-mgmt.yaml
kind get kubeconfig --name mgmt > mgmt.kubeconfig
```

!!! tip "Why a separate kubeconfig file?"
    You'll work with two clusters: `mgmt` (the provider) and `tenant-a` (the customer). Keeping one kubeconfig file and one alias for each makes it obvious which cluster you're talking to.

Create an alias to quickly manage the kind cluster:
```sh
alias kmgmt='kubectl --kubeconfig mgmt.kubeconfig'
```

Verify the kind cluster:
```sh
kmgmt get nodes
```

```text
NAME                 STATUS   ROLES           AGE   VERSION
mgmt-control-plane   Ready    control-plane   30s   v1.36.4
mgmt-worker          Ready    <none>          20s   v1.36.4
mgmt-worker2         Ready    <none>          20s   v1.36.4
```
