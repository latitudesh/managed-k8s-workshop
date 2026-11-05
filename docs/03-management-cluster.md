# 3. Create the kind cluster (mgmt)

This is the provider's **management cluster**. Customers never see it, and it hosts their control planes. It has 1 control plane node and 2 workers, which gives the tenant control plane Pods and the etcd datastore room to spread out, like a small provider fleet.

!!! tip "Use `sudo` if needed"
    If your user is not part of the `docker` group, you'll need to prepend the `kind` and `docker` commands with `sudo` or [add your user to the docker group](https://docs.docker.com/engine/install/linux-postinstall/#add-your-user-to-the-docker-group).

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

!!! tip "Execute the `alias` command again if opening a new terminal"
    If you open a new terminal, you'll need to execute the `alias` command again.

Verify the kind cluster:
```sh
kmgmt get nodes
```

```{ .text .no-copy title="Output" }
NAME                 STATUS   ROLES           AGE   VERSION
mgmt-control-plane   Ready    control-plane   30s   v1.36.4
mgmt-worker          Ready    <none>          20s   v1.36.4
mgmt-worker2         Ready    <none>          20s   v1.36.4
```

You have the provider's management cluster. Next, [start cloud-provider-kind](04-cloud-provider-kind.md), so `LoadBalancer` Services can get an IP.
