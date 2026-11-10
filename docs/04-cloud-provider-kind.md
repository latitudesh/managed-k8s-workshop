# 4. Start cloud-provider-kind

On a cloud, a `LoadBalancer` Service gets a real load balancer and an external IP. kind has no cloud, so these Services stay `<pending>` forever. `cloud-provider-kind` fills the gap: it watches for `LoadBalancer` Services and starts an Envoy container on the `kind` Docker network for each one, with its own IP.

This is how the `tenant-a` API server will get a reachable address like `172.18.0.5:6443`, just like a provider puts a load balancer in front of your control plane.

Start `cloud-provider-kind` in a separate terminal. Leave it running during the entire workshop.

On macOS:
```sh
sudo cloud-provider-kind
```

On Linux:
```sh
cloud-provider-kind
```

!!! tip "Why `sudo` on macOS?"
    On macOS, Docker runs inside a VM, so container IPs aren't reachable from your machine. `cloud-provider-kind` works around this with port mappings on the host, which needs extra privileges.

!!! warning "macOS firewall"
    If macOS asks whether `cloud-provider-kind` can accept incoming network connections, click **Allow**. With the firewall on and the answer set to block, the load balancer addresses won't work from your machine. See [Troubleshooting: macOS firewall](troubleshooting.md#macos-firewall) if that happens.

--8<-- "vevox-checkpoint.md"

Leave it running. Next, [install the platform](05-helm-packages.md) on `mgmt`: cert-manager, Kamaji and etcd.
