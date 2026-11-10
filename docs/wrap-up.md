# Wrap-up

<div class="lat-hero" markdown>

<p class="lat-hero__label">./wrap-up</p>

<p class="lat-hero__title">You built a managed Kubernetes provider.</p>

<p class="lat-hero__text" markdown>You started with a "Create Cluster" button and ended with everything behind it running on your laptop. Those are the pieces every managed Kubernetes provider has to build, [LKS](lks.md) included. Now imagine running them for thousands of clusters, with upgrades every quarter. That's what "managed" means.</p>

</div>

<p class="lat-label">./what-you-built</p>

## What you built

<div class="lat-goals lat-goals--wrap">
  <div class="lat-goal"><span class="lat-goal__n">1</span><span class="lat-goal__text">A management cluster that hosts a customer control plane as ordinary Pods, with Kamaji and a shared etcd.</span></div>
  <div class="lat-goal"><span class="lat-goal__n">2</span><span class="lat-goal__text">A worker node in another network that joined through a load balancer and never saw the control plane Pods.</span></div>
  <div class="lat-goal"><span class="lat-goal__n">3</span><span class="lat-goal__text">The boundary between the provider's network and the customer's, the features it breaks, and Konnectivity as the fix.</span></div>
  <div class="lat-goal"><span class="lat-goal__n">4</span><span class="lat-goal__text">An upgrade the way providers do it: control plane in place, workers by replacement.</span></div>
  <div class="lat-goal"><span class="lat-goal__n">5</span><span class="lat-goal__text">Add-ons installed from the provider side with Sveltos.</span></div>
</div>

<p class="lat-label">./keep-going</p>

## Keep going

<div class="lat-products">
  <a class="lat-card" href="../14-lks/">
    <span class="lat-badge lat-badge--prod">Step 14</span>
    <span class="lat-card__title">Run the workshop on LKS</span>
    <span class="lat-card__text">The same build on real infrastructure: an LKS cluster as the management cluster and a bare metal server as the worker node.</span>
  </a>
  <a class="lat-card" href="https://www.latitude.sh/docs/lks">
    <span class="lat-badge lat-badge--prod">Docs</span>
    <span class="lat-card__title">Read the LKS docs</span>
    <span class="lat-card__text">How the managed version handles networking, storage and upgrades.</span>
  </a>
  <a class="lat-card" href="https://github.com/latitudesh/managed-k8s-workshop/issues">
    <span class="lat-badge lat-badge--prod">GitHub</span>
    <span class="lat-card__title">Found a problem or have an idea?</span>
    <span class="lat-card__text">Open an issue in the workshop repository. The whole thing is MPL-2.0.</span>
  </a>
</div>

Go deeper into the tools: [Kamaji](https://kamaji.clastix.io/) for hosted control planes, [Sveltos](https://projectsveltos.github.io/sveltos/) for add-ons and [Konnectivity](https://kubernetes.io/docs/tasks/extend-kubernetes/setup-konnectivity/) for the tunnel.

<p class="lat-label">./on-the-house</p>

## Apply for $1,000 in LKS credits

Want to run this on real bare metal? Latitude.sh is giving $1,000 in LKS credits to people who apply. Scan the QR code or open [latitude.sh/lks-wishlist](https://www.latitude.sh/lks-wishlist) to join the waitlist.

<div class="lat-slide" markdown>

[![Deploy Kubernetes on bare metal. Apply for $1,000 in LKS credits. Scan to join the waitlist.](assets/lks-credits.png)](https://www.latitude.sh/lks-wishlist)

<p class="lat-slide__foot" markdown>The Latitude.sh DevTools team reviews the applications. Submitting an application does not guarantee credits. [Join the waitlist](https://www.latitude.sh/lks-wishlist){ .lat-button }</p>

</div>

## Thank you

Your Pods need uptime. You need a drink. Join us for Zero Downtime, the Latitude.sh Kubernetes on bare metal happy hour: meet the team, grab a drink and talk Kubernetes beyond the expo floor. It's on Tuesday, November 10, from 5 to 8 pm, at Repeal in Salt Lake City. Scan the QR code or [RSVP on Luma](https://luma.com/j906i3rf). Spots are limited.

<div class="lat-slide" markdown>

[![Thank you. Kubernetes on bare metal, drinks on us. Scan to RSVP, spots are limited.](assets/happy-hour.png)](https://luma.com/j906i3rf)

<p class="lat-slide__foot" markdown>Tuesday, November 10, 5 to 8 pm, Repeal, Salt Lake City. [RSVP on Luma](https://luma.com/j906i3rf){ .lat-button }</p>

</div>

<p class="lat-label">./q-and-a</p>

## Q&A

<!-- Live, in the room. This stays on the projector while we take questions:
     a line of text and the two QR slides, side by side, so people can scan
     them meanwhile. -->

Time for questions. Ask us anything about the workshop, LKS or Kubernetes on bare metal.

<div class="qr-pair" markdown>

[![Deploy Kubernetes on bare metal. Apply for $1,000 in LKS credits. Scan to join the waitlist.](assets/lks-credits.png)](https://www.latitude.sh/lks-wishlist)

[![Thank you. Kubernetes on bare metal, drinks on us. Scan to RSVP, spots are limited.](assets/happy-hour.png)](https://luma.com/j906i3rf)

</div>
