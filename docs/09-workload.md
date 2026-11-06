# 9. Run a workload

Create a Deployment:
```sh
kta create deployment web --image=nginx:1.29 --replicas=2
```

```{ .text .no-copy title="Output" }
deployment.apps/web created
```

Expose it with a NodePort Service:
```sh
kta create service nodeport web --tcp=80:80 --node-port=30080
```

```{ .text .no-copy title="Output" }
service/web created
```

Call it from the worker node:
```sh
docker exec tenant-a-worker-1 curl http://localhost:30080 \
  --retry 10 --retry-all-errors --retry-delay 2
```

```{ .text .no-copy title="Output" }
[...]
<p><em>Thank you for using nginx.</em></p>
[...]
```

The workload works: the scheduler placed the Pods, the kubelet started them, and Cilium routes the Service. All of it only needs the node → API server direction.

Logs fail :(
```sh
kta logs deploy/web -f --request-timeout 5s
```

```{ .text .no-copy title="Output" }
Found 2 pods, using pod/web-795767664d-sl6tx
Get "https://172.18.0.5:6443/api/v1/namespaces/default/pods/web-795767664d-sl6tx/log?container=nginx&follow=true&timeout=5s": context deadline exceeded
Unable to connect to the server: context deadline exceeded
```

- `context deadline exceeded`: `kubectl` reached the API server, but the API server never got an answer from the kubelet.

Exec too (it takes about a minute to fail):
```sh
kta exec deploy/web -- hostname
```

```{ .text .no-copy title="Output" }
error: unable to upgrade connection: error dialing backend: dial tcp 172.18.0.6:10250: i/o timeout
```

- `dial tcp 172.18.0.6:10250`: the API server tried to open a connection to the kubelet on the worker node.
- `i/o timeout`: our iptables rule dropped it.

Workloads run, but anything where the API server has to call the kubelet is dead. Next, [fix it with Konnectivity](10-konnectivity.md).
