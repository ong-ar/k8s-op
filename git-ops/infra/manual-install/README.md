# Manual Install Configuration

This directory contains `values.yaml` files for components that require manual installation during the initial cluster bootstrap.

## Structure

```
git-ops/infra/manual-install/
├── calico/
│   └── values.yaml    # CNI Configuration
└── argo-cd/
    └── values.yaml    # Argo CD Configuration
```

## Installation Commands

### 1. Calico (CNI)

```bash
cd git-ops/infra/manual-install/calico

helm repo add projectcalico https://projectcalico.docs.tigera.io/charts
helm repo update

helm upgrade --install calico projectcalico/tigera-operator \
  --version 3.31.0 \
  -n tigera-operator --create-namespace \
  -f values.yaml
```

### 2. Argo CD

```bash
cd git-ops/infra/manual-install/argo-cd

helm repo add argo https://argoproj.github.io/argo-helm
helm repo update

helm upgrade --install argocd argo/argo-cd \
  --version 8.5.8 \
  -n argo-cd --create-namespace \
  -f values.yaml
```

## Installation Order

During the bootstrap phase, please install in the following order:

1. **Calico** (Required for Networking)
2. **Argo CD** (Required for GitOps)

Once Argo CD is installed, other components will be deployed automatically via GitOps.
