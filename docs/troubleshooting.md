# Troubleshooting

The problems people hit while running this workshop on different machines. Each entry starts with the symptom, says which step it shows up in, and gives the fix. The steps link here when they're the ones most likely to trigger it.

## `Progress deadline exceeded` when installing cert-manager

**Where:** [5.1 cert-manager](05-helm-packages.md#51-cert-manager). The `helm upgrade --install` command gives up after 5 minutes with `Progress deadline exceeded`.

Check the Pods with `kmgmt -n cert-manager get pods`. If they're in `ImagePullBackOff` and `kmgmt -n cert-manager get events` shows `x509: certificate signed by unknown authority`, a VPN or security agent on your machine is inspecting TLS. See [Prerequisites](01-prerequisites.md). After pausing it, delete the Pods so they retry right away, then run the `helm` command again:
```sh
kmgmt -n cert-manager delete pod --all
```

## `connection reset by peer` on `172.18.0.5:6443` (macOS)

**Where:** [6.2 Connect to tenant-a](06-hosted-control-plane.md#62-connect-to-tenant-a). `kta version` fails right away with `connection reset by peer`, while the worker container can reach the same address.

On macOS, `cloud-provider-kind` gives your machine the load balancer IP as an alias on the loopback interface, and runs a small tunnel on `172.18.0.5:6443` that forwards to the Envoy container. The macOS firewall treats that tunnel as an incoming connection to `cloud-provider-kind`. If the firewall is on and the app is set to block, the TCP connection opens and is reset right away, with nothing in the `cloud-provider-kind` logs.

Check the rule. The path is the one your install uses; this is what it looks like with Homebrew on Apple silicon:
```sh
/usr/libexec/ApplicationFirewall/socketfilterfw --listapps \
  | grep -A1 cloud-provider-kind
```

```{ .text .no-copy title="Output" }
/opt/homebrew/Cellar/cloud-provider-kind/0.12.0/bin/cloud-provider-kind
             (Block incoming connections)
```

Allow it in System Settings, under Network, Firewall, Options, switching `cloud-provider-kind` to **Allow incoming connections**, or from the terminal. `realpath` follows the Homebrew symlink to the binary the firewall registered:
```sh
sudo /usr/libexec/ApplicationFirewall/socketfilterfw \
  --unblockapp "$(realpath "$(command -v cloud-provider-kind)")"
```

On a company-managed Mac, both can be locked by a profile. In that case, skip the tunnel: only `kubectl` on your machine goes through it, the containers reach the load balancer directly on the `kind` network. Point the alias at the port Docker mapped for the Envoy container. The port changes whenever `cloud-provider-kind` recreates the container, so look it up on every call:
```sh
tenant_a_url() {
  port=$(docker port $(docker ps -q --filter name=kindccm) 6443/tcp \
    | head -1 | cut -d: -f2)
  echo "https://127.0.0.1:$port"
}
alias kta='kubectl --kubeconfig tenant-a.kubeconfig --server $(tenant_a_url)'
```

The API server certificate includes `127.0.0.1`, so TLS verification still works. Everything else in the workshop stays the same, including `TENANT_A_APISERVER_IP`, which the worker node uses from inside the Docker network.

### Helm needs the workaround too

**Where:** [7.2 Install a CNI](07-worker-node.md#72-install-a-cni), if you're using the `kta` alias from the entry above. The Cilium `helm upgrade --install` fails right away with `kubernetes cluster unreachable: Get "https://172.18.0.5:6443/version": ... connection reset by peer`.

`helm` reads the kubeconfig directly and ignores the `kta` alias, so it hits the blocked tunnel. Point it at the Docker port with `--kube-apiserver`. The API server certificate includes `127.0.0.1`, so TLS verification still works:
```sh
TENANT_A_LOCAL_PORT=$(docker port $(docker ps -q --filter name=kindccm) \
  6443/tcp | head -1 | cut -d: -f2)

helm upgrade --install cilium cilium/cilium --version 1.20.2 \
  --kubeconfig tenant-a.kubeconfig \
  --kube-apiserver https://127.0.0.1:$TENANT_A_LOCAL_PORT \
  --namespace kube-system \
  --set kubeProxyReplacement=true \
  --set k8sServiceHost=$TENANT_A_APISERVER_IP \
  --set k8sServicePort=6443 \
  --set ipam.mode=kubernetes \
  --set operator.replicas=1
```

`k8sServiceHost` stays `172.18.0.5`: that address is used by the Cilium agent on the worker node, inside the Docker network.
