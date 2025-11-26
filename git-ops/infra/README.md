# Kubernetes Cluster GitOps Repository

This repository contains configuration files for managing the Kubernetes cluster infrastructure and applications using **GitOps** practices.

## 🚀 Getting Started

When setting up the cluster for the first time, you must manually install the essential components (`Calico`, `Argo CD`) in the following order.
All subsequent infrastructure (`Cert Manager`, `Ingress Nginx`, `Loki`, `MinIO`, etc.) will be automatically deployed via Argo CD.

### Prerequisites

- Kubernetes Cluster (Master/Worker Nodes ready)
- `kubectl` (Cluster access configured)
- `helm` (v3 or higher)

---

## 1. Essential Network & Tool Installation (Manual Install)

Use the scripts and configuration files located in the `git-ops/infra/manual-install/` directory for the initial bootstrap.

### 1-1. Install Calico (CNI)

You must install the network plugin for Pod communication first.

```bash
# Move to directory
cd git-ops/infra/manual-install/calico

# Add Helm Repository
helm repo add projectcalico https://projectcalico.docs.tigera.io/charts
helm repo update

# Install Calico
helm upgrade --install calico projectcalico/tigera-operator \
  --version 3.31.0 \
  -n tigera-operator --create-namespace \
  -f values.yaml

# Verify Installation
kubectl get pods -n calico-system
```

### 1-2. Install Argo CD

Install Argo CD, the core tool for GitOps.

```bash
# Move to directory
cd ../argo-cd

# Add Helm Repository
helm repo add argo https://argoproj.github.io/argo-helm
helm repo update

# Install Argo CD
helm upgrade --install argocd argo/argo-cd \
  --version 8.5.8 \
  -n argo-cd --create-namespace \
  -f values.yaml

# Verify Installation (Wait until all Pods are Running)
kubectl get pods -n argo-cd
```

> **Note:** Check Initial Admin Password
>
> ```bash
> kubectl -n argo-cd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d; echo
> ```

---

## 2. GitOps Bootstrap

Once Argo CD is installed, connect this repository to automatically build the rest of the infrastructure.

### 2-1. Deploy Root Application (App of Apps)

First, apply the AppProject:

```bash
kubectl apply -f git-ops/infra/app-project.yaml
```

Then, deploy the **Root Application** which manages all other infrastructure components. You can apply the following manifest:

```bash
cat <<EOF | kubectl apply -f -
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: infra-root
  namespace: argo-cd
spec:
  project: infra-structure
  source:
    repoURL: https://github.com/ong-ar/k8s-op.git
    targetRevision: main
    path: git-ops/infra
    directory:
      recurse: true
  destination:
    server: https://kubernetes.default.svc
    namespace: argo-cd
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
      - CreateNamespace=true
EOF
```

### 2-2. Automatically Deployed Components & Verification

Once Argo CD synchronizes (Sync), the following components will be automatically installed.

#### 📊 Prometheus & Grafana (Monitoring)

- **Namespace**: `monitoring`
- **Check Grafana Admin Password**:
  ```bash
  kubectl get secret -n monitoring kube-prometheus-stack-grafana -o jsonpath="{.data.admin-password}" | base64 -d; echo
  ```

#### 🔐 Argo CD (GitOps)

- **Namespace**: `argo-cd`
- **Check Initial Admin Password**:
  ```bash
  kubectl -n argo-cd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d; echo
  ```

#### Other Components

- **Cert Manager**: Certificate management
- **Ingress NGINX**: Ingress controller
- **Longhorn**: Distributed storage
- **Loki & Promtail**: Logging system
- **MinIO**: Object storage
- **Sealed Secrets**: Secret encryption management
- **Reflector**: Secret/ConfigMap replication

---

## 📂 Directory Structure

```
.
├── git-ops
│   └── infra/              # Infrastructure managed by Argo CD (GitOps)
│       ├── argo-cd/        # (Self-managed Argo CD configurations, etc.)
│       ├── cert-manager/
│       ├── ingress-nginx/
│       ├── loki/
│       ├── minio/
│       ├── ...
│       └── manual-install/ # Manual installation files for initial cluster setup
│           ├── argo-cd/    # Helm Values for initial Argo CD installation
│           └── calico/     # Helm Values for CNI installation
```
