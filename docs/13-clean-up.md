# 13. Clean up

Delete the kind cluster. This removes the management cluster, and with it the `tenant-a` control plane and its state in etcd:
```sh
kind delete cluster --name mgmt
```

Delete the worker node containers. They aren't part of the kind cluster, so `kind` doesn't know about them:
```sh
docker rm -fv tenant-a-worker-1 tenant-a-worker-2 2>/dev/null
```

Stop `cloud-provider-kind` with `Ctrl+C` in its terminal.

Delete the kubeconfig files:
```sh
rm -f mgmt.kubeconfig tenant-a.kubeconfig
```
