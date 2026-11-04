# Managed Kubernetes Workshop

**Build your own managed Kubernetes provider, on your laptop.**

When you click "Create Cluster" on a managed Kubernetes platform, like [LKS](https://www.latitude.sh/docs/lks), you get a working API server in a few minutes, but you never see the control plane. This workshop shows what's behind that button: you'll build the same pieces a provider might run, step by step, and hit the same problems they had to solve.

**Read the workshop at [latitudesh.github.io/managed-k8s-workshop](https://latitudesh.github.io/managed-k8s-workshop/).**

## What's in this repository

- `docs/`: the workshop, one page per step. Start at [`docs/index.md`](docs/index.md).
- `manifests/`: the Kubernetes manifests the workshop applies. Every command runs from the root of this repository and references them by relative path.
- `mkdocs.yml`: the site configuration ([MkDocs](https://www.mkdocs.org/) with the [Material](https://squidfunk.github.io/mkdocs-material/) theme).

## Run the site locally

```
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
mkdocs serve
```

Open http://127.0.0.1:8000/managed-k8s-workshop/. The site reloads when you edit anything under `docs/`.
