# Contributing

The workshop lives in `docs/`, one Markdown file per step, and is published with [MkDocs](https://www.mkdocs.org/) and the [Material](https://squidfunk.github.io/mkdocs-material/) theme.

## Run the site locally

You need Python 3.9 or newer.

```
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
mkdocs serve
```

Open http://127.0.0.1:8000/managed-k8s-workshop/. The site rebuilds and reloads the browser whenever you save a file under `docs/` or `mkdocs.yml`.

If you use [uv](https://docs.astral.sh/uv/) instead:

```
uv venv .venv
uv pip install -r requirements.txt
.venv/bin/mkdocs serve
```

## Check before opening a PR

Every pull request that touches the docs runs the build in strict mode as a check, so a broken link or a missing file fails before it reaches `main`. Run the same command locally:

```
mkdocs build --strict
```

The `site/` folder it creates is ignored by git.

## Layout

| Path | What it is |
| --- | --- |
| `docs/index.md` | The introduction: what you'll build and the list of steps |
| `docs/latitude.md` | What Latitude.sh and LKS are, and how LKS maps to the steps |
| `docs/hosts.md` | Who's giving the workshop, with photos in `docs/assets/` |
| `docs/wrap-up.md` | The closing page: recap, the LKS credits offer and where to go next |
| `docs/NN-slug.md` | One file per step, numbered in the order of the workshop |
| `docs/troubleshooting.md` | Every known problem, with the symptom, where it shows up and the fix |
| `docs/stylesheets/extra.css` | The Latitude.sh colors and the custom blocks described below |
| `docs/assets/` | Logo and favicon |
| `manifests/` | The Kubernetes manifests the workshop applies |
| `mkdocs.yml` | Site configuration and navigation |

## Writing conventions

**Steps.** Each page starts with an `# N. Title` heading and uses `## N.M Subtitle` for subsections. The numbers are part of the heading because the text refers to them ("as in 7.2"), and the heading matches the entry in `nav`. When you add a step, add it to `nav` in `mkdocs.yml` too. Each page ends with one sentence that says what the reader has now and links to the next step.

**Commands and output.** A command goes in a `sh` block. Its output goes right after it in an output block, which has a label, dimmer styling and no copy button:

````
Verify the Kamaji Pods:
```sh
kmgmt -n kamaji-system get pods
```

```{ .text .no-copy title="Output" }
NAME                      READY   STATUS    RESTARTS   AGE
kamaji-667f5c4b7c-g6h5p   1/1     Running   0          116s
```
````

Trim long output with `[...]` and keep only the lines the reader needs to compare.

**Callouts.** Three kinds, all with the [admonition](https://squidfunk.github.io/mkdocs-material/reference/admonitions/) syntax:

````
!!! tip "Why a separate kubeconfig file?"
    Background that explains a choice. Skippable.

!!! warning "Pause VPNs that inspect TLS"
    Something to do before the problem happens.

!!! troubleshooting "`connection reset by peer` on `172.18.0.5:6443`?"
    See [Troubleshooting: macOS firewall](troubleshooting.md#macos-firewall).
````

Keep the fix itself in `docs/troubleshooting.md` and leave only the symptom and a link in the step. Each entry there starts with a `**Where:**` line that links back to the step, and its heading carries a short explicit id, `## Symptom { #macos-firewall }`, so the link from the step doesn't depend on the heading text.

**Links.** Link to other pages by file name, `[7.2 Install a CNI](07-worker-node.md#72-install-a-cni)`. The anchor is the heading in lowercase with spaces as hyphens and punctuation removed. Link to manifests with their GitHub URL, so the link works on the site.

**Diagrams.** Use a `mermaid` block. The theme renders it in both color schemes.

## Publishing

Pushing to `main` runs `.github/workflows/deploy-pages.yml`, which builds the site and deploys it to GitHub Pages at https://latitudesh.github.io/managed-k8s-workshop/. The workflow can also be started by hand from the Actions tab.
