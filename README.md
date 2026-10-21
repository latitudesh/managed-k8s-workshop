# Managed Kubernetes Workshop

## Prerequisites

Install kind.  
Install [cloud-kind-provider](https://github.com/kubernetes-sigs/cloud-provider-kind).  
Install Helm.  

## Create Kind Cluster (mgmt)

Create the Kind Cluster:
```
kind create cluster --config manifests/kind-mgmt.yaml
kind get kubeconfig --name mgmt > mgmt.kubeconfig
```

Create alias to quickly manage the Kind Cluster:
```
alias kmgmt='kubectl --kubeconfig mgmt.kubeconfig'
```

Verify Kind Cluster:
```
kmgmt get nodes
```

## Start cloud-kind-provider
Start `cloud-kind-provider` on a separated terminal. Leave it running during the entire workshop.

On OSX:
```
sudo cloud-provider-kind
```

On Linux:
```
cloud-provider-kind
```

## Install Helm packages
Add Helm repositories and update them:
```
helm repo add jetstack https://charts.jetstack.io
helm repo add cilium https://helm.cilium.io
helm repo add clastix https://clastix.github.io/charts

helm repo update
```

### cert-manager
Used to generate the entire Kubernetes PKI infrastructure.

Install cert-manager:
```
helm upgrade --install cert-manager jetstack/cert-manager \
  --kubeconfig mgmt.kubeconfig \
  --namespace cert-manager \
  --create-namespace \
  --version v1.21.2 \
  --set crds.enabled=true \
  --wait
```

### Kamaji
Responsible to manage the Tenant Control Planes.

Install Kamaji:
```
helm upgrade --install kamaji charts/kamaji \
  --kubeconfig mgmt.kubeconfig \
  --namespace kamaji-system \
  --create-namespace \
  --wait 
```

Verify Kamaji Pods:
```
kmgmt -n kamaji-system get pods
```

Verify Kamaji Datastores:
```
kmgmt get datastores
```

## Create your first Hosted Control Plane (tenant-a)


Create the `tenant-a` Control Plane:
```
kmgmt apply -f manifests/tenant-a.yaml
```

Verify until it becomes `Ready`:
```
kmgmt -n tenant-a get tenantcontrolplane tenant-a -w 

NAME       VERSION   INSTALLED VERSION   STATUS   CONTROL-PLANE ENDPOINT   KUBECONFIG                  DATASTORE   AGE
tenant-a   v1.36.4   v1.36.4             Ready    172.18.0.5:6443          tenant-a-admin-kubeconfig   default     25m
```

All resources created:
```
kmgmt -n tenant-a get deploy,pods,svc,secrets

NAME                       READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/tenant-a   2/2     2            2           26m

NAME                            READY   STATUS    RESTARTS   AGE
pod/tenant-a-6d9cc8b4c7-g7xsl   3/3     Running   0          26m
pod/tenant-a-6d9cc8b4c7-rb2dp   3/3     Running   0          26m

NAME               TYPE           CLUSTER-IP     EXTERNAL-IP   PORT(S)          AGE
service/tenant-a   LoadBalancer   10.96.75.221   172.18.0.5    6443:30383/TCP   26m

NAME                                                    TYPE     DATA   AGE
secret/tenant-a-admin-kubeconfig                        Opaque   4      26m
secret/tenant-a-api-server-certificate                  Opaque   2      26m
secret/tenant-a-api-server-kubelet-client-certificate   Opaque   2      26m
secret/tenant-a-ca                                      Opaque   4      26m
secret/tenant-a-controller-manager-kubeconfig           Opaque   1      26m
secret/tenant-a-datastore-certificate                   Opaque   3      26m
secret/tenant-a-datastore-config                        Opaque   4      26m
secret/tenant-a-front-proxy-ca-certificate              Opaque   2      26m
secret/tenant-a-front-proxy-client-certificate          Opaque   2      26m
secret/tenant-a-sa-certificate                          Opaque   2      26m
secret/tenant-a-scheduler-kubeconfig                    Opaque   1      26m
```

The Pods run our known Kubernetes resources as containers!
```
kmgmt -n tenant-a get pods -l kamaji.clastix.io/name=tenant-a \
  -o jsonpath='{range .items[0].spec.containers[*]}{.name}{"\n"}{end}'

kube-apiserver
kube-scheduler
kube-controller-manager
```

Where the `kube-apiserver` listens too?
```
kmgmt -n tenant-a get deploy tenant-a -o yaml | grep -E -- '--advertise-address'

        - --advertise-address=172.18.0.5
```

And the `etcd` configuration?
```
kmgmt -n tenant-a get deploy tenant-a -o yaml | grep -E -- '--etcd'

        - --etcd-cafile=/etc/kubernetes/pki/etcd/ca.crt
        - --etcd-certfile=/etc/kubernetes/pki/etcd/server.crt
        - --etcd-compaction-interval=0
        - --etcd-keyfile=/etc/kubernetes/pki/etcd/server.key
        - --etcd-prefix=/88b0d4cb-9d91-4063-9ed6-e17d63cc4b91
        - --etcd-servers=https://kamaji-etcd-0.kamaji-etcd.kamaji-system.svc.cluster.local:2379,https://kamaji-etcd-1.kamaji-etcd.kamaji-system.svc.cluster.local:2379,https://kamaji-etcd-2.kamaji-etcd.kamaji-system.svc.cluster.local:237
```

Get the `tenant-a`'s kubeconfig:
```
kmgmt -n tenant-a get secret tenant-a-admin-kubeconfig -o jsonpath='{.data.admin\.conf}' | base64 -d > tenant-a.kubeconfig
```

Create a little alias to make our life easier:
```
alias kta='kubectl --kubeconfig tenant-a.kubeconfig'
```

Verify our newly created Kubernetes Cluster:
```
kta version

Client Version: v1.36.2
Kustomize Version: v5.8.1
Server Version: v1.36.4
```

```
kta get nodes

No resources found
```

```
kta get pods -A

NAMESPACE     NAME                       READY   STATUS    RESTARTS   AGE
kube-system   coredns-695c5d47b8-59chl   0/1     Pending   0          32m
kube-system   coredns-695c5d47b8-94lmr   0/1     Pending   0          32m
```

```
kta get ns

NAME              STATUS   AGE
default           Active   32m
kube-node-lease   Active   32m
kube-public       Active   32m
kube-system       Active   32m
```

### Export helpful variables

```
export TENANT_A_APISERVER_IP=$(kmgmt -n tenant-a get svc tenant-a -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
```

## Join a Worker Node

Create the Worker Node as a Docker container:
```
docker run -d --name tenant-a-worker-1 --hostname tenant-a-worker-1 --network kind --privileged --volume /var kindest/node:v1.36.4
```

Verify it is up and running:
```
docker ps | grep tenant-a-worker-1

c91963f9fe57   kindest/node:v1.36.4            "/usr/local/bin/entr…"   49 seconds ago   Up 49 seconds      tenant-a-worker-1
```

Exec into the container and verify if it can reach the `tenant-a` `kube-apiserver`: 
```
docker exec -ti tenant-a-worker-1 curl -k "https://$TENANT_A_APISERVER_IP:6443"

{
  "kind": "Status",
  "apiVersion": "v1",
  "metadata": {},
  "status": "Failure",
  "message": "forbidden: User \"system:anonymous\" cannot get path \"/\"",
  "reason": "Forbidden",
  "details": {},
  "code": 403
}
```

Copy the Control Plane's kubeconfig into the Worker Node:
```
docker cp tenant-a.kubeconfig tenant-a-worker-1:/root/tenant.kubeconfig

Successfully copied 5.63kB (transferred 7.17kB) to tenant-a-worker-1:/root/tenant.kubeconfig
```

Generate the kubeadm join command:
```
JOIN=$(docker exec tenant-a-worker-1 kubeadm token create --print-join-command --kubeconfig /root/tenant.kubeconfig)
echo $JOIN

kubeadm join 172.18.0.5:6443 --token ls243t.sometoken --discovery-token-ca-cert-hash sha256:a92cdecf603641ccb519121d96e4111d72ce6d6ab3b5d4305ff65a1b962b0e03
```

Run the kubeadm join command:
```
docker exec tenant-a-worker-1 sh -c "$JOIN --ignore-preflight-errors=all"

[...]
Run 'kubectl get nodes' on the control-plane to see this node join the cluster.
```

Verify the Worker Node has joined!
```
kta get node

NAME                STATUS     ROLES    AGE     VERSION
tenant-a-worker-1   NotReady   <none>   4m57s   v1.36.4
```

Pods are still not running, we need a CNI:
```
kta get pod -A

NAMESPACE     NAME                       READY   STATUS    RESTARTS   AGE
kube-system   coredns-695c5d47b8-ndv5c   0/1     Pending   0          12m
kube-system   coredns-695c5d47b8-twmks   0/1     Pending   0          12m
```

Install Cilium CNI:
```
helm upgrade --install cilium cilium/cilium --version 1.20.2 \
  --kubeconfig tenant-a.kubeconfig \
  --namespace kube-system \
  --set kubeProxyReplacement=true \
  --set k8sServiceHost=$TENANT_A_APISERVER_IP \
  --set k8sServicePort=6443 \
  --set ipam.mode=kubernetes \
  --set operator.replicas=1
```

Verify the Worker Node gets `Ready`:
```
kta get nodes -w           

NAME                STATUS   ROLES    AGE   VERSION
tenant-a-worker-1   Ready    <none>   12m   v1.36.4
```

Verify the Pods gets all `Ready`:
```
kta get pods -A 

NAMESPACE     NAME                               READY   STATUS    RESTARTS   AGE
kube-system   cilium-envoy-tjn5n                 1/1     Running   0          2m28s
kube-system   cilium-htbgw                       1/1     Running   0          2m28s
kube-system   cilium-operator-6647c45686-mspfd   1/1     Running   0          2m27s
kube-system   coredns-695c5d47b8-ndv5c           1/1     Running   0          20m
kube-system   coredns-695c5d47b8-twmks           1/1     Running   0          20m
```

## Simulating a real world managed Kubernetes network

```
for n in $(kind get nodes --name mgmt); do
  ip=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' "$n")
  docker exec tenant-a-worker-1 iptables -I INPUT -p tcp --dport 10250 -s "$ip" -j DROP
done

docker exec tenant-a-worker-1 iptables -L INPUT -n | grep 10250 
```

## Let's run a workload
```
kta create deployment web --image=nginx:1.29 --replicas=2

deployment.apps/web created
```

```
kta create service nodeport web --tcp=80:80 --node-port=30080

service/web created
```

```
docker exec tenant-a-worker-1 curl http://localhost:30080 --retry 10 --retry-all-errors --retry-delay

[...]
<p><em>Thank you for using nginx.</em></p>
[...]
```

Logs fail :(
```
kta logs deploy/web -f --request-timeout 5s

Found 2 pods, using pod/web-795767664d-5vvhs
Get "https://172.18.0.5:6443/api/v1/namespaces/default/pods/web-795767664d-5vvhs/log?container=nginx&follow=true&timeout=5s": context deadline exceeded
Unable to connect to the server: context deadline exceeded
```

Exec too:
```
kta exec pod/web-795767664d-5vvhs -- hostname

error: unable to upgrade connection: error dialing backend: dial tcp 172.18.0.6:10250: i/o timeout
```

## Fix with Konnectivity

Patch the `TenantControlPlane` resource to enable Konnectivity:
```
kmgmt -n tenant-a patch tcp tenant-a --type merge -p '{"spec":{"addons":{"konnectivity":{"server":{"port":8132},"agent":{"mode":"DaemonSet"}}}}}'

tenantcontrolplane.kamaji.clastix.io/tenant-a patched
```

Pods on the `tenant-a` Control Plane rolls. They now carry a `konnectivity-server` container.
```
kmgmt -n tenant-a get pods

NAME                       READY   STATUS    RESTARTS   AGE
tenant-a-f48bc6c89-28slj   4/4     Running   0          4m16s
tenant-a-f48bc6c89-h6szh   4/4     Running   0          4m16s
```

The Service now also exposes port 8132:
```
kmgmt -n tenant-a get svc tenant-a 

NAME       TYPE           CLUSTER-IP      EXTERNAL-IP   PORT(S)                         AGE
tenant-a   LoadBalancer   10.96.102.134   172.18.0.5    6443:30413/TCP,8132:32710/TCP   55m
```

Wait unitl the tunnel is up:
```
kta -n kube-system rollout status ds/konnectivity-agent

daemon set "konnectivity-agent" successfully rolled out
```

Now try the logs:
```
kta logs deploy/web --tail 10
```

And exec:
```
kta exec pod/web-795767664d-5vvhs -- hostname

web-795767664d-5vvhs
```

## Upgrade Kubernetes

### Upgrade the Control Plane

In a second terminal, keep an eye on the `tenant-a` Control Plane Pods:
```
kmgmt -n tenant-a get pods -w

NAME                       READY   STATUS    RESTARTS   AGE
tenant-a-f48bc6c89-28slj   4/4     Running   0          17m
tenant-a-f48bc6c89-h6szh   4/4     Running   0          17m
```

Patch the `TenantControlPlane` with a new Kubernetes version:
```
kmgmt -n tenant-a patch tenantcontrolplane tenant-a --type merge -p '{"spec":{"kubernetes":{"version":"v1.37.0"}}}'
```

Verify the `TenantControlPlane` resource status (`Upgrading` -> `Ready`):
```
kmgmt -n tenant-a get tenantcontrolplane tenant-a -w
```

Verify, from `tenant-a`'s perspective, the new Kubernetes version:
```
kta version

Client Version: v1.36.2
Kustomize Version: v5.8.1
Server Version: v1.37.0
```

And the Worker Node is still v1.36.4:
```
kta get node

NAME                STATUS   ROLES    AGE   VERSION
tenant-a-worker-1   Ready    <none>   66m   v1.36.4
```

### Upgrade the Worker Node
Upgrade by replacing the Node, like the managed providers do.

Add a new Worker Node with v1.37.0:
```
docker run -d --name tenant-a-worker-2 --hostname tenant-a-worker-2 --network kind --privileged --volume /var kindest/node:v1.37.0

docker cp tenant-a.kubeconfig tenant-a-worker-2:/root/tenant.kubeconfig

JOIN=$(docker exec tenant-a-worker-2 kubeadm token create --print-join-command --kubeconfig /root/tenant.kubeconfig)

docker exec tenant-a-worker-2 sh -c "$JOIN --ignore-preflight-errors=all"
```

Verify the new Worker Node arrived in the Cluster:
```
kta get node -w

[...]
tenant-a-worker-2   Ready      <none>   44s   v1.37.0
```

Drain and remove the old Worker Node:
```
kta drain tenant-a-worker-1 --ignore-daemonsets --delete-emptydir-data --force 

kta delete node tenant-a-worker-1

docker rm -f tenant-a-worker-1
```

## Clean up

Delete Kind Cluster:
```
kind delete cluster --name mgmt
```

Delete Docker containers:
```
docker rm -fv tenant-a-worker-1 tenant-a-worker-2 2>/dev/null
```
