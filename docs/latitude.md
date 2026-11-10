# Latitude.sh

<!-- Icons and the hero background come from latitude.sh itself
     (static/product-icons, static/metal/why, static/home). The layout
     follows the site: section labels like "./products", chrome icons on
     dark cards, numbers in lime. -->

<div class="lat-hero" markdown>

<p class="lat-hero__label">./latitude.sh</p>

<p class="lat-hero__title">The power of bare metal meets the flexibility of the cloud.</p>

<p class="lat-hero__text">Latitude.sh is a bare metal cloud. You get a whole physical server, dedicated to you, and you deploy it the way you'd deploy a VM: from a dashboard, an API or Terraform, in seconds.</p>

</div>

<p class="lat-label">./bare-metal</p>

## What bare metal means

In a public cloud, a VM is a slice of a server. A hypervisor carves the machine up and your neighbors run on the same hardware. On Latitude.sh, the server is yours alone. There's nothing between your operating system and the metal.

<div class="lat-compare">
  <div class="lat-stack lat-stack--vm">
    <p class="lat-stack__title">A VM in a public cloud</p>
    <div class="lat-layer">Your app</div>
    <div class="lat-layer">Guest OS</div>
    <div class="lat-layer lat-layer--dim">Hypervisor</div>
    <div class="lat-layer lat-layer--dim">Shared hardware<small>you, and whoever else landed on this box</small></div>
    <p class="lat-stack__note">Shared cores, shared memory bandwidth, shared disks. Performance depends on the neighbors.</p>
  </div>
  <div class="lat-stack lat-stack--metal">
    <p class="lat-stack__title">A Latitude.sh server</p>
    <div class="lat-layer">Your app</div>
    <div class="lat-layer">OS</div>
    <div class="lat-layer lat-layer--lime">The whole server<small>every core, every GPU, every disk: yours</small></div>
    <p class="lat-stack__note">No hypervisor and no neighbors. Still provisioned, rebooted and deleted through an API, like a VM.</p>
  </div>
</div>

<p class="lat-label">./why-latitude.sh</p>

## Why it matters

<div class="lat-stats">
  <div class="lat-stat">
    <img src="../assets/latitude/dial.png" alt="">
    <p class="lat-stat__big">Under 5 s</p>
    <p class="lat-stat__text">From "deploy" to a server with an IP, via the dashboard, API or Terraform.</p>
  </div>
  <div class="lat-stat">
    <img src="../assets/latitude/metal.png" alt="">
    <p class="lat-stat__big">No hypervisor</p>
    <p class="lat-stat__text">Dedicated hardware with zero virtualization overhead. Every core is yours.</p>
  </div>
  <div class="lat-stat">
    <img src="../assets/latitude/network.png" alt="">
    <p class="lat-stat__big">25 locations</p>
    <p class="lat-stat__text">On 5 continents, on Latitude.sh's own carrier-grade network. Deploy next to your users.</p>
  </div>
  <div class="lat-stat">
    <img src="../assets/latitude/cloud.png" alt="">
    <p class="lat-stat__big">Cloud-like</p>
    <p class="lat-stat__text">On-demand or reserved, billed by the hour, automated end to end. Bare metal without the data center.</p>
  </div>
</div>

See how a server is deployed from the dashboard below.

<div class="arcade-embed">
<iframe src="https://demo.arcade.software/3CXMlyH59yYfX8rY17Wt?embed&embed_mobile=tab&embed_desktop=inline&squared=true&disable_border=true&show_copy_link=true&utm_content=/managed-k8s-workshop/latitude" title="Deploy a server" referrerpolicy="no-referrer-when-downgrade" frameborder="0" loading="lazy" allowfullscreen allow="clipboard-write; autoplay"></iframe>
</div>

<p class="lat-label">./products</p>

## One home for your infrastructure

Three verticals, all owned and operated by Latitude.sh and integrated by design. The colors are the ones the site uses for each. LKS, the managed Kubernetes, has [its own page](lks.md) next.

<div class="lat-vertical lat-vertical--compute">
  <div class="lat-vertical__head">
    <img src="../assets/latitude/metal.png" alt="">
    <span class="lat-vertical__name">Compute</span>
    <span class="lat-vertical__tag">Dedicated servers, with and without GPUs, and VMs when a whole server is too much.</span>
  </div>
  <div class="lat-vertical__grid">
    <a class="lat-vcard" href="https://www.latitude.sh/metal"><span class="lat-vcard__title">Metal</span><span class="lat-vcard__text">Automated bare metal servers, deployed globally in under 5 seconds.</span></a>
    <a class="lat-vcard" href="https://www.latitude.sh/accelerate"><span class="lat-vcard__title">Metal GPU</span><span class="lat-vcard__text">Dedicated GPU servers and clusters, pre-configured with ML tooling.</span></a>
    <a class="lat-vcard" href="https://www.latitude.sh/virtual-machines"><span class="lat-vcard__title">Virtual Machines</span><span class="lat-vcard__text">General-purpose VMs with a global footprint.</span></a>
  </div>
</div>

<div class="lat-vertical lat-vertical--storage">
  <div class="lat-vertical__head">
    <img src="../assets/latitude/storage.png" alt="">
    <span class="lat-vertical__name">Storage</span>
    <span class="lat-vertical__tag">Data that outlives the server it's attached to.</span>
  </div>
  <div class="lat-vertical__grid">
    <a class="lat-vcard" href="https://www.latitude.sh/storage"><span class="lat-vcard__title">Object</span><span class="lat-vcard__text">S3-compatible buckets to store, retrieve and manage your data.</span></a>
    <a class="lat-vcard" href="https://www.latitude.sh/storage"><span class="lat-vcard__title">File</span><span class="lat-vcard__text">Shared filesystems, mounted by many servers at once.</span></a>
    <a class="lat-vcard" href="https://www.latitude.sh/storage"><span class="lat-vcard__title">Block</span><span class="lat-vcard__text">NVMe-native volumes that attach to a server and follow your workload.</span></a>
    <a class="lat-vcard" href="https://www.latitude.sh/databases"><span class="lat-vcard__title">Managed PostgreSQL</span><span class="lat-vcard__text">Fully managed database instances next to your servers.</span></a>
  </div>
</div>

<div class="lat-vertical lat-vertical--network">
  <div class="lat-vertical__head">
    <img src="../assets/latitude/network.png" alt="">
    <span class="lat-vertical__name">Networking</span>
    <span class="lat-vertical__tag">Latitude.sh's own carrier-grade network, around the servers and out to other clouds.</span>
  </div>
  <div class="lat-vertical__grid">
    <a class="lat-vcard" href="https://www.latitude.sh/network"><span class="lat-vcard__title">Private networks and Elastic IPs</span><span class="lat-vcard__text">Private VLANs between servers, and portable IPv4 addresses you move between servers or announce over BGP. Bring your own IPs too.</span></a>
    <a class="lat-vcard" href="https://www.latitude.sh/cloud-gateway"><span class="lat-vcard__title">Cloud Gateway</span><span class="lat-vcard__text">Privately connect Latitude.sh to AWS, GCP, Azure and more.</span></a>
    <a class="lat-vcard" href="https://www.latitude.sh/global-gateway"><span class="lat-vcard__title">Global Gateway</span><span class="lat-vcard__text">Private interconnection between Latitude.sh locations.</span></a>
    <a class="lat-vcard" href="https://www.latitude.sh/ddos-protection"><span class="lat-vcard__title">Firewall and DDoS protection</span><span class="lat-vcard__text">Server-level protection, managed from the dashboard or API.</span></a>
  </div>
</div>

<p class="lat-label">./deploy-metal.sh</p>

## Your servers. Your tools.

Everything above sits behind the same API. The same server, deployed six ways:

<div class="lat-ways">
  <a class="lat-way" href="https://www.latitude.sh/docs/dashboard/overview">
    <span class="lat-way__k">ui</span>
    <span class="lat-way__title">Dashboard</span>
    <span class="lat-way__text">Pick a plan, a location and an OS, click Deploy.</span>
    <code class="lat-way__code">Bare metal → Deploy</code>
  </a>
  <a class="lat-way" href="https://www.latitude.sh/docs/api-reference/summary">
    <span class="lat-way__k">api</span>
    <span class="lat-way__title">REST API</span>
    <span class="lat-way__text">Everything the dashboard does, as HTTP calls.</span>
    <code class="lat-way__code">POST /servers</code>
  </a>
  <a class="lat-way" href="https://www.latitude.sh/docs/cli">
    <span class="lat-way__k">lsh</span>
    <span class="lat-way__title">CLI</span>
    <span class="lat-way__text">The API from your terminal.</span>
    <code class="lat-way__code">lsh servers create</code>
  </a>
  <a class="lat-way" href="https://www.latitude.sh/docs/guides/terraform">
    <span class="lat-way__k">tf</span>
    <span class="lat-way__title">Terraform</span>
    <span class="lat-way__text">Servers, networks and IPs as code.</span>
    <code class="lat-way__code">latitudesh_server {}</code>
  </a>
  <a class="lat-way" href="https://www.latitude.sh/docs/client-libraries">
    <span class="lat-way__k">sdk</span>
    <span class="lat-way__title">SDKs</span>
    <span class="lat-way__text">TypeScript, Go and Python clients.</span>
    <code class="lat-way__code">servers.create(…)</code>
  </a>
  <a class="lat-way" href="https://www.latitude.sh/docs/development/model-context-protocol">
    <span class="lat-way__k">mcp</span>
    <span class="lat-way__title">MCP server</span>
    <span class="lat-way__text">Your AI assistant drives the API for you.</span>
    <code class="lat-way__code">"deploy a server"</code>
  </a>
</div>

Next, [LKS](lks.md), the product this workshop takes apart.
