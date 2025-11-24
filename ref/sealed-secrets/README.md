# install

## commands

```bash
helm repo add sealed-secrets https://bitnami-labs.github.io/sealed-secrets
helm repo update
```

## Private Key 고정 (재사용)

Sealed Secrets의 private key를 고정하여 클러스터 재설치 시에도 동일한 키를 사용할 수 있습니다.
cert-manager의 GCP DNS key처럼 미리 생성하여 재사용합니다.

### 1. 기존 클러스터에서 키 백업 (최초 1회)

```bash
# 기존 sealed-secrets의 private key 백업
kubectl get secret -n sealed-secrets sealed-secrets-key -o yaml > sealed-secrets-key.yaml

# 또는 sealed-secrets가 kube-system에 있는 경우
kubectl get secret -n kube-system sealed-secrets-key -o yaml > sealed-secrets-key.yaml

# 키 파일을 안전한 곳에 보관 (Git에 커밋하지 말 것!)
```

### 2. 새 클러스터에 키 생성/복원 (설치 전 필수)

```bash
# namespace 생성
kubectl create namespace sealed-secrets

# sealed-secrets-key Secret 생성 (설치 전에 반드시 실행)
# create-secret-key.yaml 파일에 실제 tls.crt와 tls.key 값을 입력한 후 적용
kubectl apply -f create-secret-key.yaml -n sealed-secrets

# 또는 기존 클러스터에서 백업한 키를 복원하는 경우
# kubectl apply -f sealed-secrets-key.yaml -n sealed-secrets

# 또는 kube-system에 복원하는 경우
# kubectl apply -f sealed-secrets-key.yaml -n kube-system
```

**중요**:

- `create-secret-key.yaml` 파일에 실제 `tls.crt`와 `tls.key` 값을 입력해야 합니다.
- 이 파일은 sealed-secrets 설치 전에 반드시 적용해야 합니다.

### 3. Sealed Secrets 설치

```bash
helm upgrade --install sealed-secrets sealed-secrets/sealed-secrets \
  -n sealed-secrets --create-namespace \
  --version 2.17.9 \
  -f values.yaml

helm uninstall sealed-secrets -n sealed-secrets
```

**참고**:

- 키를 미리 복원하면 sealed-secrets 컨트롤러가 기존 키를 자동으로 사용합니다.
- cert-manager의 `gcp-dns-key` Secret처럼, sealed-secrets-key도 설치 전에 미리 생성하면 됩니다.
- 키 파일은 민감 정보이므로 Git에 커밋하지 말고 안전하게 보관하세요.

## 일반 설치 (새 키 생성)

키를 고정하지 않고 새로 생성하려면:

```bash
helm upgrade --install sealed-secrets sealed-secrets/sealed-secrets \
  -n sealed-secrets --create-namespace \
  --version 2.17.9 \
  -f values.yaml
```
