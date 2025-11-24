# Manual Install

수동으로 설치해야 하는 컴포넌트들의 values.yaml 파일입니다.

## 구조

```
git-ops/manual-install/
├── calico/
│   └── values.yaml
├── ingress-nginx/
│   └── values.yaml
├── sealed-secrets/
│   └── values.yaml
├── cert-manager/
│   └── values.yaml
├── argo-cd/
│   └── values.yaml
├── longhorn/
│   └── values.yaml
├── metrics-server/
│   └── values.yaml
├── prometheus-community/
│   └── values.yaml
├── minio-operator/
│   └── values.yaml
├── minio-tenant/
│   └── values.yaml
├── loki/
│   └── values.yaml
├── promtail/
│   └── values.yaml
└── sealed-secrets-web/
    └── values.yaml
```

## 설치 명령어

### 1. Calico

```bash
cd git-ops/manual-install/calico

helm repo add projectcalico https://projectcalico.docs.tigera.io/charts
helm repo update

helm upgrade --install calico projectcalico/tigera-operator \
  --version 3.31.0 \
  -n tigera-operator --create-namespace \
  -f values.yaml
```

### 2. Ingress NGINX

```bash
cd git-ops/manual-install/ingress-nginx

helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update

helm upgrade --install ingress-nginx ingress-nginx/ingress-nginx \
  --namespace ingress-nginx \
  --create-namespace \
  --version 4.14.0 \
  -f values.yaml
```

### 3. Sealed Secrets

```bash
cd git-ops/manual-install/sealed-secrets

kubectl create namespace sealed-secrets

helm repo add sealed-secrets https://bitnami-labs.github.io/sealed-secrets
helm repo update

helm upgrade --install sealed-secrets sealed-secrets/sealed-secrets \
  -n sealed-secrets --create-namespace \
  --version 2.17.9 \
  -f values.yaml
```

### 4. cert-manager

```bash
cd git-ops/manual-install/cert-manager

kubectl create namespace cert-manager

helm repo add jetstack https://charts.jetstack.io
helm repo update

helm upgrade --install cert-manager jetstack/cert-manager \
  --namespace cert-manager \
  --create-namespace \
  --version 1.19.1 \
  -f values.yaml
```

### 5. Argo CD

```bash
cd git-ops/manual-install/argo-cd

helm repo add argo https://argoproj.github.io/argo-helm
helm repo update

helm upgrade --install argocd argo/argo-cd \
  --version 8.5.8 \
  -n argo-cd --create-namespace \
  -f values.yaml
```

### 6. Longhorn

```bash
cd git-ops/manual-install/longhorn

helm repo add longhorn https://charts.longhorn.io
helm repo update

helm upgrade --install longhorn longhorn/longhorn \
  --namespace longhorn-system --create-namespace \
  --version 1.10.1 \
  -f values.yaml
```

### 7. Metrics Server

```bash
cd git-ops/manual-install/metrics-server

helm repo add metrics-server https://kubernetes-sigs.github.io/metrics-server/
helm repo update

helm upgrade --install metrics-server metrics-server/metrics-server \
  --version 3.12.2 \
  -n kube-system --create-namespace \
  -f values.yaml
```

### 8. Prometheus Community

```bash
cd git-ops/manual-install/prometheus-community

helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

helm upgrade --install kube-prometheus-stack prometheus-community/kube-prometheus-stack \
  --version 79.5.0 \
  -n monitoring --create-namespace \
  -f values.yaml
```

### 9. MinIO Operator

```bash
cd git-ops/manual-install/minio-operator

helm repo add minio-operator https://operator.min.io
helm repo update

helm upgrade --install minio-operator minio-operator/operator \
  --version 7.1.1 \
  -n minio-operator --create-namespace \
  -f values.yaml
```

### 10. MinIO Tenant

```bash
cd git-ops/manual-install/minio-tenant

helm repo add minio-operator https://operator.min.io
helm repo update

helm upgrade --install tenant-loki minio-operator/tenant \
  --version 7.1.1 \
  -n tenant-loki --create-namespace \
  -f values.yaml
```

### 11. Loki

```bash
cd git-ops/manual-install/loki

helm repo add grafana https://grafana.github.io/helm-charts
helm repo update

helm upgrade --install loki grafana/loki \
  --version 6.41.1 \
  -n loki --create-namespace \
  -f values.yaml
```

### 12. Promtail

```bash
cd git-ops/manual-install/promtail

helm repo add grafana https://grafana.github.io/helm-charts
helm repo update

helm upgrade --install promtail grafana/promtail \
  --version 6.17.0 \
  -n loki \
  -f values.yaml
```

### 13. Sealed Secrets Web

```bash
cd git-ops/manual-install/sealed-secrets-web

helm repo add bakito https://charts.bakito.net
helm repo update

helm upgrade --install sealed-secrets-web bakito/sealed-secrets-web \
  -n sealed-secrets-web --create-namespace \
  -f values.yaml
```

## 설치 순서

Bootstrap 단계에서는 다음 순서로 설치합니다:

1. **Calico** (CNI - 필수)
2. **Ingress NGINX** (필수)
3. **Sealed Secrets** (필수)
4. **cert-manager** (필수)
5. **Argo CD** (필수)

나머지 컴포넌트는 Argo CD 설치 후 필요에 따라 설치합니다.

## 참고

- 모든 values.yaml 파일은 `git-ops/infra/<component>/application.yaml`의 `helm.values`에서 추출했습니다.
- 실제 설치 시에는 각 컴포넌트의 README나 공식 문서를 참고하세요.
