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

--8<-- "vevox-checkpoint.md"

That's the end of the main path. If you have access to Latitude.sh, the optional step [runs the same thing on LKS](14-lks.md). It doesn't need anything you just deleted, and it reuses the aliases and file names, so cleaning up first avoids mixing the two `tenant-a` clusters. Otherwise, head to the [Wrap-up](wrap-up.md) for a recap, the LKS credits offer and where to go next.
