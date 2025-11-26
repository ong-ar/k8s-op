# Kubernetes Cluster GitOps Repository

This repository contains configuration files for managing the Kubernetes cluster infrastructure and applications using **GitOps** practices.

## 🚀 Getting Started

When setting up the cluster for the first time, you must manually install the essential components (`Calico`, `Argo CD`) in the following order.
All subsequent infrastructure will be deployed via Argo CD **sequentially**.

### Prerequisites

- Kubernetes Cluster (Master/Worker Nodes ready)
- `kubectl` (Cluster access configured)
- `helm` (v3 or higher)

---

## 1. Essential Network & Tool Installation (Manual Install)

Use the scripts and configuration files located in the `git-ops/infra/.manual-install/` directory for the initial bootstrap.

### 1-1. Install Calico (CNI)

You must install the network plugin for Pod communication first.

```bash
# Move to directory
cd git-ops/infra/.manual-install/calico

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

## 2. GitOps Bootstrap (Sequential Apply)

Once Argo CD is installed, apply the applications in the following order to ensure dependencies are met.

### 2-1. Apply AppProject

First, apply the `infra-structure` project:

```bash
kubectl apply -f git-ops/infra/app-project.yaml
```

### 2-2. Apply Base Infrastructure

These components are required for other applications to function (Secret management, Certificates, Ingress).

> **⚠️ Important:** Before applying Sealed Secrets, you must restore your **Private Key** if you are migrating or reinstalling.
> If you don't restore the key, existing encrypted secrets will not be decryptable.
>
> ```bash
> # Example: Restore Master Key
> kubectl apply -f master-key.yaml
> ```

```bash
# 1. Sealed Secrets (Encryption)
kubectl apply -f git-ops/infra/sealed-secrets/application.yaml

# 2. Cert Manager (TLS Certificates)
kubectl apply -f git-ops/infra/cert-manager/application.yaml

# 3. Reflector (Secret Replication)
kubectl apply -f git-ops/infra/reflector/application.yaml

# 4. Ingress NGINX (Ingress Controller)
kubectl apply -f git-ops/infra/ingress-nginx/application.yaml
```

> **Wait:** Ensure `cert-manager` and `ingress-nginx` are fully running before proceeding.

### 2-3. Apply Storage & Monitoring

```bash
# 5. Longhorn (Distributed Storage)
kubectl apply -f git-ops/infra/longhorn/application.yaml

# 6. Prometheus & Grafana (Monitoring)
kubectl apply -f git-ops/infra/prometheus-community/application.yaml

# 7. Metrics Server
kubectl apply -f git-ops/infra/metrics-server/application.yaml
```

### 2-4. Apply Applications

```bash
# 8. MinIO Operator & Tenant (Object Storage)
kubectl apply -f git-ops/infra/minio/operator/application.yaml
kubectl apply -f git-ops/infra/minio/tenant/application.yaml

# 9. Loki & Promtail (Logging)
kubectl apply -f git-ops/infra/loki/loki/application.yaml
kubectl apply -f git-ops/infra/loki/promtail/application.yaml

# 10. Sealed Secrets Web (UI)
kubectl apply -f git-ops/infra/sealed-secrets-web/application.yaml
```

---

## 3. Verification & Access

### 📊 Prometheus & Grafana

- **Namespace**: `monitoring`
- **Check Grafana Admin Password**:
  ```bash
  kubectl get secret -n monitoring prometheus-community-grafana -o jsonpath="{.data.admin-password}" | base64 -d; echo
  ```

### 🔐 Argo CD

- **Namespace**: `argo-cd`
- **Check Initial Admin Password**:
  ```bash
  kubectl -n argo-cd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d; echo
  ```

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
│       └── .manual-install/# Manual installation files for initial cluster setup
│           ├── argo-cd/    # Helm Values for initial Argo CD installation
│           └── calico/     # Helm Values for CNI installation
```
