# Bootstrap 가이드

Argo CD를 배포하기 전에 필요한 인프라 컴포넌트를 수동으로 설치하는 순서입니다.

## 설치 순서

### 1. Calico (CNI) - 필수

Pod 네트워킹을 위한 CNI 플러그인입니다. 클러스터 생성 직후 가장 먼저 설치해야 합니다.

```bash
cd calico

# Helm repository 추가
helm repo add projectcalico https://projectcalico.docs.tigera.io/charts
helm repo update

# 설치
helm upgrade --install calico projectcalico/tigera-operator \
  --version 3.31.0 \
  -n tigera-operator --create-namespace \
  -f values.yaml

# 상태 확인
kubectl get pods -n tigera-operator
kubectl get pods -n calico-system -o wide
kubectl get nodes -o wide  # 모든 노드가 Ready 상태인지 확인
```

**확인 사항:**

- 모든 노드가 `Ready` 상태
- `calico-system` namespace의 Pod들이 모두 Running

---

### 2. Ingress NGINX - 필수

Argo CD Ingress 접근을 위한 Ingress Controller입니다.

```bash
cd ingress-nginx

# Helm repository 추가
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update

# 설치
helm upgrade --install ingress-nginx ingress-nginx/ingress-nginx \
  --namespace ingress-nginx \
  --create-namespace \
  --version 4.14.0 \
  -f values.yaml

# 상태 확인
kubectl get pods -n ingress-nginx -o wide
kubectl get ds -n ingress-nginx
```

**확인 사항:**

- `ingress-nginx` namespace의 Pod들이 모두 Running
- DaemonSet이 모든 노드에 스케줄링됨

---

### 3. Sealed Secrets - 필수

Git에 Secret을 안전하게 저장하기 위한 Sealed Secrets입니다.

#### 3-1. Private Key 생성/복원 (설치 전 필수)

```bash
cd sealed-secrets

# namespace 생성
kubectl create namespace sealed-secrets

# sealed-secrets-key Secret 생성 (설치 전에 반드시 실행)
# 기존 키를 재사용하는 경우: create-secret-key.yaml 파일에 실제 키 값 입력 후 적용
# 새 키를 생성하는 경우: sealed-secrets 설치 후 자동 생성된 키를 백업하여 사용
kubectl apply -f create-secret-key.yaml -n sealed-secrets

# 또는 기존 클러스터에서 백업한 키를 복원하는 경우
# kubectl apply -f sealed-secrets-key.yaml -n sealed-secrets
```

**중요**: `create-secret-key.yaml` 파일에 실제 `tls.crt`와 `tls.key` 값을 입력해야 합니다.

#### 3-2. Sealed Secrets 설치

```bash
# Helm repository 추가
helm repo add sealed-secrets https://bitnami-labs.github.io/sealed-secrets
helm repo update

# 설치
helm upgrade --install sealed-secrets sealed-secrets/sealed-secrets \
  -n sealed-secrets --create-namespace \
  --version 2.17.9 \
  -f values.yaml

# 상태 확인
kubectl get pods -n sealed-secrets
```

**확인 사항:**

- `sealed-secrets` namespace의 Pod가 Running
- `kubectl get sealedsecrets` 명령어가 동작하는지 확인

---

### 4. cert-manager - 필수

TLS 인증서 자동 발급을 위한 cert-manager입니다.

#### 4-1. GCP DNS Key Secret 생성 (Sealed Secret 사용)

```bash
cd cert-manager

# namespace 생성 (cert-manager 설치 전에 필요)
kubectl create namespace cert-manager

# Sealed Secret으로 암호화된 GCP DNS Key 적용
kubectl apply -f create-secret-key-json.yaml

# Secret이 생성되었는지 확인
kubectl get secret gcp-dns-key -n cert-manager
```

**참고:** `create-secret-key-json.yaml`은 SealedSecret입니다.
실제 `key.json` 파일이 있다면 다음 명령어로 직접 생성할 수도 있습니다:

```bash
# namespace가 없으면 먼저 생성
kubectl create namespace cert-manager

# Secret 생성
kubectl create secret generic gcp-dns-key \
  --namespace cert-manager \
  --dry-run=client -o yaml \
  --from-file=key.json=../key.json \
  | kubectl apply -f -
```

#### 4-2. cert-manager 설치

```bash
# Helm repository 추가
helm repo add jetstack https://charts.jetstack.io
helm repo update

# 설치
helm upgrade --install cert-manager jetstack/cert-manager \
  --namespace cert-manager \
  --create-namespace \
  --version 1.19.1 \
  -f values.yaml

# 상태 확인
kubectl get pods -n cert-manager
```

#### 4-3. ClusterIssuer 및 Certificate 생성

```bash
# ClusterIssuer 생성
kubectl apply -f yaml/create-cluster-issuer-archainia.yaml

# Certificate 생성 (각 namespace에)
kubectl apply -f yaml/certificate-archainia.yaml -n argo-cd
kubectl apply -f yaml/certificate-archainia.yaml -n longhorn-system
kubectl apply -f yaml/certificate-archainia.yaml -n monitoring

# 상태 확인
kubectl get clusterissuer
kubectl get certificate -A
```

**확인 사항:**

- `cert-manager` namespace의 Pod들이 모두 Running
- ClusterIssuer가 Ready 상태
- Certificate가 Issued 상태

---

### 5. Argo CD - 필수

GitOps를 위한 Argo CD입니다.

```bash
cd argo-cd

# Helm repository 추가
helm repo add argo https://argoproj.github.io/argo-helm
helm repo update

# 설치
helm upgrade --install argocd argo/argo-cd \
  --version 8.5.8 \
  -n argo-cd --create-namespace \
  -f values.yaml

# 상태 확인
kubectl get pods -n argo-cd
kubectl get pods -n argo-cd -o wide
```

#### 5-1. Argo CD Ingress 배포

```bash
# Ingress 배포
kubectl apply -f ingress.yaml

# 상태 확인
kubectl get ingress -n argo-cd
```

#### 5-2. 초기 Admin Password 확인

```bash
# 초기 admin password 확인
kubectl -n argo-cd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
echo
```

**확인 사항:**

- `argo-cd` namespace의 모든 Pod들이 Running
- Ingress가 정상적으로 생성됨
- Argo CD UI에 접근 가능한지 확인

---

## 전체 설치 스크립트 (참고용)

```bash
#!/bin/bash
set -e

echo "=== 1. Calico 설치 ==="
cd calico
helm repo add projectcalico https://projectcalico.docs.tigera.io/charts
helm repo update
helm upgrade --install calico projectcalico/tigera-operator \
  --version 3.31.0 \
  -n tigera-operator --create-namespace \
  -f values.yaml
kubectl wait --for=condition=ready pod -l k8s-app=calico-node -n calico-system --timeout=300s
cd ..

echo "=== 2. Ingress NGINX 설치 ==="
cd ingress-nginx
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update
helm upgrade --install ingress-nginx ingress-nginx/ingress-nginx \
  --namespace ingress-nginx \
  --create-namespace \
  --version 4.14.0 \
  -f values.yaml
kubectl wait --for=condition=ready pod -l app.kubernetes.io/component=controller -n ingress-nginx --timeout=300s
cd ..

echo "=== 3. Sealed Secrets 설치 ==="
cd sealed-secrets
kubectl create namespace sealed-secrets --dry-run=client -o yaml | kubectl apply -f -
# sealed-secrets-key Secret 생성 (설치 전 필수)
kubectl apply -f create-secret-key.yaml -n sealed-secrets
# 또는 기존 키 복원 (있는 경우)
if [ -f sealed-secrets-key.yaml ]; then
  kubectl apply -f sealed-secrets-key.yaml -n sealed-secrets
fi
helm repo add sealed-secrets https://bitnami-labs.github.io/sealed-secrets
helm repo update
helm upgrade --install sealed-secrets sealed-secrets/sealed-secrets \
  -n sealed-secrets --create-namespace \
  --version 2.17.9 \
  -f values.yaml
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=sealed-secrets -n sealed-secrets --timeout=300s
cd ..

echo "=== 4. cert-manager 설치 ==="
cd cert-manager
# namespace 생성 (Secret 생성 전에 필요)
kubectl create namespace cert-manager --dry-run=client -o yaml | kubectl apply -f -
# GCP DNS Key Secret 생성 (namespace 생성 후)
kubectl apply -f create-secret-key-json.yaml
helm repo add jetstack https://charts.jetstack.io
helm repo update
helm upgrade --install cert-manager jetstack/cert-manager \
  --namespace cert-manager \
  --create-namespace \
  --version 1.19.1 \
  -f values.yaml
kubectl wait --for=condition=ready pod -l app.kubernetes.io/instance=cert-manager -n cert-manager --timeout=300s
# ClusterIssuer 및 Certificate 생성
kubectl apply -f yaml/create-cluster-issuer-archainia.yaml
kubectl apply -f yaml/certificate-archainia.yaml -n argo-cd
cd ..

echo "=== 5. Argo CD 설치 ==="
cd argo-cd
helm repo add argo https://argoproj.github.io/argo-helm
helm repo update
helm upgrade --install argocd argo/argo-cd \
  --version 8.5.8 \
  -n argo-cd --create-namespace \
  -f values.yaml
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=argocd-server -n argo-cd --timeout=300s
kubectl apply -f ingress.yaml
cd ..

echo "=== Bootstrap 완료 ==="
echo "Argo CD 초기 비밀번호:"
kubectl -n argo-cd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
echo
```

## 의존성 다이어그램

```
Kubernetes Cluster
    ↓
[1] Calico (CNI) - Pod 네트워킹
    ↓
[2] Ingress NGINX - 외부 접근
    ↓
[3] Sealed Secrets - Secret 관리
    ↓
[4] cert-manager - TLS 인증서
    ↓
[5] Argo CD - GitOps
    ↓
나머지 인프라 (Argo CD로 자동화)
```

## 주의사항

1. **순서 준수**: 각 단계는 이전 단계가 완료된 후 진행해야 합니다.
2. **상태 확인**: 각 단계마다 Pod 상태를 확인하고 다음 단계로 진행하세요.
3. **Secret 관리**:
   - `sealed-secrets-key.yaml`은 Git에 커밋하지 마세요.
   - `key.json` (GCP DNS Key)도 Git에 커밋하지 마세요.
4. **네임스페이스**: 각 컴포넌트는 지정된 namespace에 설치됩니다.

## 트러블슈팅

### Calico Pod가 시작되지 않는 경우

- 노드의 네트워크 설정 확인
- CNI 설정 확인

### Ingress NGINX가 동작하지 않는 경우

- DaemonSet이 모든 노드에 스케줄링되었는지 확인
- `hostNetwork: true` 설정 확인

### Sealed Secrets가 동작하지 않는 경우

- 키가 올바르게 복원되었는지 확인
- `kubectl get sealedsecrets` 명령어로 CRD 확인

### cert-manager가 인증서를 발급하지 않는 경우

- GCP DNS Key Secret이 올바르게 생성되었는지 확인
- ClusterIssuer 상태 확인: `kubectl describe clusterissuer`
- Certificate 이벤트 확인: `kubectl describe certificate -n <namespace>`

### Argo CD에 접근할 수 없는 경우

- Ingress가 정상적으로 생성되었는지 확인
- DNS 설정 확인
- TLS 인증서가 발급되었는지 확인
