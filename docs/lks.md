# LKS

<!-- Based on latitude.sh/lks, shortened. Same components as docs/latitude.md
     (hero, ./labels, stacks, cards), icons from docs/assets/latitude/. -->

<div class="lat-hero" markdown>

<p class="lat-hero__label">./latitude-kubernetes-service</p>

<p class="lat-hero__title">Kubernetes runs better on bare metal.</p>

<p class="lat-hero__text">LKS (Latitude Kubernetes Service) runs upstream Kubernetes on dedicated bare metal, with a fully managed control plane, flexible node pools and persistent storage for your workloads.</p>

</div>

<p class="lat-label">./managed-kubernetes</p>

## Who runs what

A managed Kubernetes service splits a cluster in two. The provider operates the control plane. The customer operates the nodes, where the workloads actually run. You never see the control plane: you create a cluster, get a kubeconfig, add nodes and start deploying.

<div class="lat-compare">
  <div class="lat-stack">
    <p class="lat-stack__title">Latitude.sh operates</p>
    <div class="lat-layer lat-layer--dim">kube-apiserver</div>
    <div class="lat-layer lat-layer--dim">etcd</div>
    <div class="lat-layer lat-layer--dim">kube-scheduler</div>
    <div class="lat-layer lat-layer--dim">kube-controller-manager</div>
    <p class="lat-stack__note">The control plane, highly available. No nodes to SSH into, no etcd to back up, nothing to patch. Upstream Kubernetes, so standard tooling works as is.</p>
  </div>
  <div class="lat-stack lat-stack--metal">
    <p class="lat-stack__title">You operate</p>
    <div class="lat-layer lat-layer--lime">Your workloads<small>kubectl, Helm, the manifests you already have</small></div>
    <div class="lat-layer">Node pools<small>groups of dedicated bare metal servers, CPU or GPU</small></div>
    <p class="lat-stack__note">You pick the plan, the size, the labels and the taints. LKS provisions the servers, joins them and keeps them healthy.</p>
  </div>
</div>

<p class="lat-label">./features</p>

## Kubernetes, without the infrastructure overhead

<div class="lat-products">
  <div class="lat-card">
    <img src="../assets/latitude/gateway.png" alt="">
    <span class="lat-card__title">Managed control plane</span>
    <span class="lat-card__text">A highly available Kubernetes control plane, operated and maintained by Latitude.sh.</span>
  </div>
  <div class="lat-card">
    <img src="../assets/latitude/metal.png" alt="">
    <span class="lat-card__title">Bare metal node pools</span>
    <span class="lat-card__text">Run CPU and GPU workloads directly on dedicated hardware, without virtualization overhead.</span>
  </div>
  <div class="lat-card">
    <img src="../assets/latitude/build.png" alt="">
    <span class="lat-card__title">Flexible node pools</span>
    <span class="lat-card__text">Provision new servers or bring the Latitude.sh servers you already have. Run both kinds in the same cluster.</span>
  </div>
  <div class="lat-card">
    <img src="../assets/latitude/storage.png" alt="">
    <span class="lat-card__title">Persistent block storage</span>
    <span class="lat-card__text">A <code>PersistentVolumeClaim</code> gets a block storage volume that follows the Pod between nodes and outlives it.</span>
  </div>
  <div class="lat-card">
    <img src="../assets/latitude/network.png" alt="">
    <span class="lat-card__title">Built-in load balancing</span>
    <span class="lat-card__text">A <code>LoadBalancer</code> Service gets an Elastic IP announced over BGP. Cilium is the CNI. L4 only, so bring your own Ingress or Gateway.</span>
  </div>
  <div class="lat-card">
    <img src="../assets/latitude/vm.png" alt="">
    <span class="lat-card__title">Standard Kubernetes tooling</span>
    <span class="lat-card__text">Deploy and manage workloads with kubectl, Helm and the Kubernetes workflows you already use.</span>
  </div>
</div>

<p class="lat-label">./use-cases</p>

## What people run on LKS

<div class="lat-products">
  <div class="lat-card">
    <img src="../assets/latitude/gpu.png" alt="">
    <span class="lat-card__title">AI training and inference</span>
    <span class="lat-card__text">GPU node pools on dedicated servers, with the GPU scheduling and the tooling you already use in Kubernetes. No virtualization in the way.</span>
  </div>
  <div class="lat-card">
    <img src="../assets/latitude/databases.png" alt="">
    <span class="lat-card__title">Stateful workloads</span>
    <span class="lat-card__text">Databases, queues and caches on persistent block storage that follows the Pod, on NVMe, with no noisy neighbors.</span>
  </div>
  <div class="lat-card">
    <img src="../assets/latitude/metal.png" alt="">
    <span class="lat-card__title">Latency-sensitive services</span>
    <span class="lat-card__text">APIs, game servers, streaming and real-time systems that want bare metal performance and an Elastic IP close to the users.</span>
  </div>
  <div class="lat-card">
    <img src="../assets/latitude/cloud.png" alt="">
    <span class="lat-card__title">Leaving the public cloud bill behind</span>
    <span class="lat-card__text">Move clusters from a hyperscaler onto bare metal with predictable pricing, and keep a private link back through Cloud Gateway while you migrate.</span>
  </div>
</div>

<p class="lat-label">./deploy</p>

## From zero to kubectl in four steps

<div class="lat-steps">
  <div class="lat-step"><span class="lat-step__n">01</span><span class="lat-step__title">Create a cluster</span><span class="lat-step__text">Pick a location, name it and choose a Kubernetes version.</span></div>
  <div class="lat-step"><span class="lat-step__n">02</span><span class="lat-step__title">Add node pools</span><span class="lat-step__text">Provision new servers on demand, or allocate servers you already have.</span></div>
  <div class="lat-step"><span class="lat-step__n">03</span><span class="lat-step__title">Get your kubeconfig</span><span class="lat-step__text">Download it from the dashboard once the cluster is active.</span></div>
  <div class="lat-step"><span class="lat-step__n">04</span><span class="lat-step__title">Deploy</span><span class="lat-step__text">Use kubectl, Helm and the tools you already know.</span></div>
</div>

```sh
kubectl --kubeconfig=./my-cluster-kubeconfig.yaml get nodes
```

<p class="lat-label">./locations</p>

## Deploy where your workloads run

<div class="lat-locations">
  <div class="lat-locations__lead">
    <span class="lat-locations__big">7</span>
    <span class="lat-locations__label">locations with LKS, on Latitude.sh's own bare metal</span>
  </div>
  <div class="lat-locations__regions">
    <div class="lat-region">
      <span class="lat-region__name">North America</span>
      <div class="lat-region__grid">
        <span class="lat-loc"><span class="lat-loc__code">ASH</span>Ashburn</span>
        <span class="lat-loc"><span class="lat-loc__code">CHI</span>Chicago</span>
        <span class="lat-loc"><span class="lat-loc__code">DAL</span>Dallas</span>
        <span class="lat-loc"><span class="lat-loc__code">LAX</span>Los Angeles</span>
        <span class="lat-loc"><span class="lat-loc__code">TOR</span>Toronto</span>
      </div>
    </div>
    <div class="lat-region">
      <span class="lat-region__name">Europe</span>
      <div class="lat-region__grid">
        <span class="lat-loc"><span class="lat-loc__code">LON</span>London</span>
      </div>
    </div>
    <div class="lat-region">
      <span class="lat-region__name">APAC</span>
      <div class="lat-region__grid">
        <span class="lat-loc"><span class="lat-loc__code">TYO</span>Tokyo</span>
      </div>
    </div>
  </div>
</div>

Full details in the [LKS docs](https://www.latitude.sh/docs/lks). Next, [On the house](credits-and-happy-hour.md): LKS credits and the happy hour.
