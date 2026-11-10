# Managed Kubernetes Workshop

<!-- Same components as docs/latitude.md and docs/lks.md: hero, ./labels,
     stacks, cards. The tool cards carry a badge that says whether the tool
     is a teaching aid for the laptop or something a provider would run. -->

<div class="lat-hero" markdown>

<p class="lat-hero__label">./managed-k8s-workshop</p>

<p class="lat-hero__title">Build your own managed Kubernetes provider, on your laptop.</p>

<p class="lat-hero__text">When you click "Create Cluster" on a managed Kubernetes platform, you get a working API server in a few minutes and never see the control plane. This workshop shows what's behind that button, by making you build it.</p>

</div>

<p class="lat-label">./goal</p>

## The goal

In two hours you'll build the pieces a managed Kubernetes provider runs, step by step, and hit the problems they had to solve. You leave knowing:

<div class="lat-goals">
  <div class="lat-goal"><span class="lat-goal__n">1</span><span class="lat-goal__title">Build the Control Plane</span><span class="lat-goal__text">Where a customer's control plane actually lives, and what "managed" means for it.</span></div>
  <div class="lat-goal"><span class="lat-goal__n">2</span><span class="lat-goal__title">Join Worker Nodes</span><span class="lat-goal__text">Why the provider's network and the customer's network are separate, what that breaks, and how a tunnel fixes it.</span></div>
  <div class="lat-goal"><span class="lat-goal__n">3</span><span class="lat-goal__title">Upgrade and Addons</span><span class="lat-goal__text">How upgrades and add-ons are rolled out from the provider's side, without touching your workloads.</span></div>
</div>

<p class="lat-label">./toolbox</p>

## The tools, and why they're here

Some of these are here because they run on a laptop. A provider would never ship them. Others are production-grade and are one way, among several, to solve the problem.

<div class="lat-products">
  <div class="lat-card">
    <span class="lat-badge lat-badge--teach">Teaching aid</span>
    <span class="lat-card__title">kind</span>
    <span class="lat-card__text">Runs the <code>mgmt</code> cluster as Docker containers. A provider runs a real fleet of servers.</span>
  </div>
  <div class="lat-card">
    <span class="lat-badge lat-badge--teach">Teaching aid</span>
    <span class="lat-card__title">Docker containers as worker nodes</span>
    <span class="lat-card__text">Stand-ins for the customer's servers. A provider's node pools are bare metal or VMs.</span>
  </div>
  <div class="lat-card">
    <span class="lat-badge lat-badge--teach">Teaching aid</span>
    <span class="lat-card__title">cloud-provider-kind</span>
    <span class="lat-card__text">Gives <code>LoadBalancer</code> Services an IP on your laptop. The real thing is the provider's load balancer.</span>
  </div>
  <div class="lat-card">
    <span class="lat-badge lat-badge--prod">Production-grade</span>
    <span class="lat-card__title">Kamaji</span>
    <span class="lat-card__text">Runs customer control planes as Pods. Open source and used in production, but one way to do it, not the way.</span>
  </div>
  <div class="lat-card">
    <span class="lat-badge lat-badge--prod">Production-grade</span>
    <span class="lat-card__title">Konnectivity</span>
    <span class="lat-card__text">The upstream Kubernetes tunnel from the control plane to the nodes. This is what providers run.</span>
  </div>
  <div class="lat-card">
    <span class="lat-badge lat-badge--prod">Production-grade</span>
    <span class="lat-card__title">Cilium</span>
    <span class="lat-card__text">The CNI. Used in production everywhere, including LKS.</span>
  </div>
  <div class="lat-card">
    <span class="lat-badge lat-badge--prod">Production-grade</span>
    <span class="lat-card__title">Sveltos</span>
    <span class="lat-card__text">Installs add-ons in every cluster from the management side. One of several tools that do this.</span>
  </div>
</div>

<p class="lat-label">./what-you-build</p>

## What you'll build

<div class="lat-diagram" markdown>

```mermaid
%%{init: {"flowchart": {"padding": 20, "nodeSpacing": 60, "rankSpacing": 60, "subGraphTitleMargin": {"top": 10, "bottom": 14}}}}%%
flowchart TB
  you(["You<br/>(kubectl)"])

  subgraph provider["Provider side: mgmt cluster (kind)"]
    kamaji["Kamaji<br/>operator"]
    etcd[("etcd<br/>shared datastore")]
    subgraph ns["namespace: tenant-a"]
      cp["tenant-a control plane<br/>kube-apiserver<br/>kube-scheduler<br/>kube-controller-manager"]
    end
    lb["LoadBalancer<br/>:6443"]
  end

  subgraph customer["Customer side: tenant-a nodes"]
    w1["tenant-a-worker-1<br/>kubelet, Cilium, your apps"]
  end

  kamaji -- "creates & manages" --> cp
  cp -- "stores state" --> etcd
  lb --> cp
  you --> lb
  w1 -- "joins & reports" --> lb
```

</div>

There are two kinds of cluster here:

- **The management cluster (`mgmt`)**: run by the provider. Users never see it. It hosts the control planes of every customer cluster.
- **The tenant cluster (`tenant-a`)**: what the customer gets. Its control plane runs as ordinary Pods inside `mgmt`. Its worker nodes run elsewhere, in the "customer's" network.

You'll use one kubeconfig for each, so always check which cluster you're talking to.

<p class="lat-label">./steps</p>

## What we'll do

Fourteen steps in five parts. Every step ends with a checkpoint, so you can tell us how it went.

<div class="lat-roadmap">
  <div class="lat-phase">
    <span class="lat-phase__name">Setup</span>
    <span class="lat-phase__text">A management cluster on your laptop, with the platform the provider runs: cert-manager, Kamaji and etcd.</span>
    <span class="lat-phase__steps">
      <a href="01-prerequisites/"><b>1</b>Prerequisites</a>
      <a href="02-workshop-files/"><b>2</b>Workshop files</a>
      <a href="03-management-cluster/"><b>3</b>kind cluster</a>
      <a href="04-cloud-provider-kind/"><b>4</b>cloud-provider-kind</a>
      <a href="05-helm-packages/"><b>5</b>Helm packages</a>
    </span>
  </div>
  <div class="lat-phase">
    <span class="lat-phase__name">Hosted control plane</span>
    <span class="lat-phase__text">A control plane for <code>tenant-a</code> as Pods in <code>mgmt</code>, then a worker node that joins it.</span>
    <span class="lat-phase__steps">
      <a href="06-hosted-control-plane/"><b>6</b>Create a control plane</a>
      <a href="07-worker-node/"><b>7</b>Join a worker node</a>
    </span>
  </div>
  <div class="lat-phase">
    <span class="lat-phase__name">Provider network</span>
    <span class="lat-phase__text">A boundary between the provider and the customer. Watch <code>kubectl logs</code> and <code>exec</code> break, then fix them with a tunnel.</span>
    <span class="lat-phase__steps">
      <a href="08-provider-network/"><b>8</b>Simulate the network</a>
      <a href="09-workload/"><b>9</b>Run a workload</a>
      <a href="10-konnectivity/"><b>10</b>Konnectivity</a>
    </span>
  </div>
  <div class="lat-phase">
    <span class="lat-phase__name">Operations</span>
    <span class="lat-phase__text">Upgrade Kubernetes the way a provider does, control plane in place and workers by replacement. Push add-ons from the management side. Clean up.</span>
    <span class="lat-phase__steps">
      <a href="11-upgrade/"><b>11</b>Upgrade</a>
      <a href="12-sveltos/"><b>12</b>Sveltos</a>
      <a href="13-clean-up/"><b>13</b>Clean up</a>
    </span>
  </div>
  <div class="lat-phase lat-phase--bonus">
    <span class="lat-badge lat-badge--teach">The tutorial is not LKS</span>
    <span class="lat-phase__name">Bonus</span>
    <span class="lat-phase__text">Steps 1 to 13 don't use LKS and don't show how LKS is built: they simulate what any managed Kubernetes provider does, with open source tools. LKS itself only shows up here, with the same build on real infrastructure: an LKS cluster and a bare metal server. Optional.</span>
    <span class="lat-phase__steps">
      <a href="14-lks/"><b>14</b>Run it on LKS</a>
    </span>
  </div>
</div>

<p class="lat-label">./who-is-this-for</p>

## Who this is for

<div class="lat-products">
  <div class="lat-card">
    <span class="lat-badge lat-badge--prod">Platform engineers</span>
    <span class="lat-card__title">Deciding between building and buying</span>
    <span class="lat-card__text">Before you run control planes for other teams, see what that actually takes: the boundary, the tunnel, the upgrades, the add-ons. Two hours of it is enough to size the job.</span>
  </div>
  <div class="lat-card">
    <span class="lat-badge lat-badge--prod">SREs and operators</span>
    <span class="lat-card__title">Running or evaluating a managed Kubernetes</span>
    <span class="lat-card__text">Know what your provider does for you, what the network boundary breaks, and what an upgrade really changes.</span>
  </div>
  <div class="lat-card">
    <span class="lat-badge lat-badge--prod">Developers</span>
    <span class="lat-card__title">Curious about the "Create Cluster" button</span>
    <span class="lat-card__text">You use managed Kubernetes every day and never saw a control plane. Two hours later, you'll have run one.</span>
  </div>
  <div class="lat-card">
    <span class="lat-badge lat-badge--prod">Learning Kubernetes internals</span>
    <span class="lat-card__title">Past the basics, before the source code</span>
    <span class="lat-card__text">API server, etcd, kubelet, CNI, the tunnel: see how the pieces fit by wiring them up yourself.</span>
  </div>
</div>

You need to be comfortable with `kubectl` and a terminal. You don't need to have run a control plane before. That's the point.

<p class="lat-label">./account</p>

## Latitude.sh account

Not for steps 1 to 13. Everything runs on your laptop in Docker.

[Step 14](14-lks.md) is the bonus round, with real infrastructure: an LKS cluster as the management cluster and a bare metal server as the worker node. For that you need a [Latitude.sh account](https://www.latitude.sh/dashboard/signup), an LKS cluster with 3 worker nodes and an Ubuntu 24.04 server. The step has its own clean-up section, so you can delete both when you're done.

Ready? Start with [1. Prerequisites](01-prerequisites.md).
