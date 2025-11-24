# Infrastructure GitOps

Argo CD로 관리하는 인프라 컴포넌트들입니다.

## 구조

```
git-ops/infra/
├── app-project.yaml          # AppProject 정의
├── calico/
│   ├── application.yaml      # Argo CD Application manifest
│   ├── values.yaml           # Helm values
│   └── kustomization.yaml
├── ingress-nginx/
│   ├── application.yaml
│   ├── values.yaml
│   └── kustomization.yaml
├── sealed-secrets/
│   ├── application.yaml
│   ├── values.yaml
│   ├── kustomization.yaml
│   └── resources/
│       └── create-secret-key.yaml
├── cert-manager/
│   ├── application.yaml
│   ├── values.yaml
│   ├── kustomization.yaml
│   └── resources/
│       ├── create-secret-key-json.yaml
│       ├── cluster-issuer.yaml
│       ├── certificate-argo-cd.yaml
│       ├── certificate-longhorn.yaml
│       └── certificate-monitoring.yaml
└── argo-cd/
    ├── application.yaml
    ├── values.yaml
    ├── kustomization.yaml
    └── resources/
        └── ingress.yaml
```

**구조 설명:**

- `application.yaml`: Argo CD Application manifest
- `values.yaml`: Helm chart values
- `kustomization.yaml`: Kustomize 설정 (resources 폴더의 YAML 파일들 참조)
- `resources/`: Kubernetes 리소스 YAML 파일들 (Certificate, Ingress, Secret 등)

## Namespace 필드 설명

### 간단 정리

**1. Argo CD 설치할 때:**

```bash
helm install -n argo-cd  # Argo CD가 argo-cd namespace에 설치됨
```

**2. AppProject/Application 만들 때:**

```yaml
metadata:
  namespace: argo-cd # 반드시 위와 같은 namespace (argo-cd)
```

→ Argo CD는 자신이 설치된 namespace에서만 AppProject/Application을 찾음

**3. Application이 배포하는 곳:**

```yaml
spec:
  destination:
    namespace: cert-manager # 실제 워크로드는 여기 배포됨
```

→ 각 Application마다 다른 namespace 사용 (cert-manager, ingress-nginx 등)

### 핵심만 기억하기

- `helm install -n argo-cd` = `metadata.namespace: argo-cd` (둘 다 `argo-cd`로 통일)
- `spec.destination.namespace` = 실제 배포할 곳 (각각 다름)

## 배포 순서

### 1. AppProject 생성

```bash
kubectl apply -f git-ops/infra/app-project.yaml
```

### 2. Applications 생성

각 Application을 생성합니다:

```bash
# Bootstrap 컴포넌트들
kubectl apply -f git-ops/infra/calico/application.yaml
kubectl apply -f git-ops/infra/ingress-nginx/application.yaml
kubectl apply -f git-ops/infra/sealed-secrets/application.yaml
kubectl apply -f git-ops/infra/cert-manager/application.yaml

# Argo CD 자체 (이미 설치된 경우 선택적)
kubectl apply -f git-ops/infra/argo-cd/application.yaml
```

또는 한 번에:

```bash
find git-ops/infra -name "application.yaml" -exec kubectl apply -f {} \;
```

## Git Repository URL 설정

모든 Application manifest에서 `<GIT_REPO_URL>`을 실제 Git repository URL로 변경해야 합니다:

```bash
find git-ops/infra -name "application.yaml" -exec sed -i '' 's|<GIT_REPO_URL>|https://github.com/your-org/k8s-op|g' {} \;
```

## 실행 순서 보장

### cert-manager의 경우

- **Wave 0**: cert-manager Helm chart 설치
- **Wave 1**: ClusterIssuer 생성 (annotation: `argocd.argoproj.io/sync-wave: "1"`)
- **Wave 2**: Certificate 생성 (annotation: `argocd.argoproj.io/sync-wave: "2"`)

sync-waves를 사용하여 실행 순서를 보장합니다.

## 주의사항

1. **Git Repository URL**: 모든 Application에서 `<GIT_REPO_URL>`을 실제 URL로 변경해야 합니다.

2. **Secret 파일**:

   - `sealed-secrets/create-secret-key.yaml`의 `tls.crt`, `tls.key` 값을 입력해야 합니다.
   - `cert-manager/create-secret-key-json.yaml`은 SealedSecret이므로 이미 암호화되어 있습니다.

3. **application.yaml 제외**:

   - 각 디렉토리의 `kustomization.yaml`에서 `application.yaml`을 제외하여 중복 실행을 방지합니다.

4. **의존성**:
   - cert-manager는 sealed-secrets 이후에 배포되어야 합니다 (GCP DNS Key Secret 필요).
   - Argo CD Ingress는 cert-manager와 ingress-nginx 이후에 배포되어야 합니다.

## Bootstrap에서 전환하기

Bootstrap으로 설치한 컴포넌트를 Argo CD로 전환하려면:

### 1. 현재 설치 상태 확인

먼저 현재 설치된 Helm release의 values를 확인합니다:

```bash
# 예: cert-manager의 현재 values 확인
helm get values cert-manager -n cert-manager

# 예: ingress-nginx의 현재 values 확인
helm get values ingress-nginx -n ingress-nginx
```

### 2. Git의 values.yaml과 일치시키기

**중요**: Git에 있는 `values.yaml`이 현재 설치된 상태와 **일치**해야 합니다.

- 현재 설치된 values와 다르면 → Git의 values.yaml을 현재 상태에 맞게 수정
- 또는 현재 설치된 상태를 Git의 values.yaml에 맞게 변경 (권장하지 않음)

### 3. Application 생성

```bash
kubectl apply -f git-ops/infra/<component>/application.yaml
```

### 4. Argo CD 동작 확인

Application을 생성하면 Argo CD는:

1. **Git 상태와 클러스터 상태 비교**

   - 일치하면 → `Synced` 상태 (문제없음)
   - 다르면 → `OutOfSync` 상태

2. **automated sync가 켜져 있으면**

   - `OutOfSync` 상태일 때 자동으로 Git 상태로 동기화 시도
   - **주의**: 현재 설정과 다르면 자동으로 변경됨!

3. **리소스 관리 시작**
   - Argo CD가 리소스를 관리하기 시작
   - 이후 모든 변경은 Git을 통해 관리

### 주의사항

⚠️ **자동 동기화 주의**:

- `syncPolicy.automated`가 켜져 있으면 Git 상태와 다를 때 자동으로 변경됩니다
- 처음 전환할 때는 `automated`를 잠시 끄고, 상태 확인 후 켜는 것을 권장합니다

```yaml
# 처음 전환 시 (수동 확인용)
syncPolicy:
  automated: false  # 수동으로 sync

# 상태 확인 후
syncPolicy:
  automated:
    prune: true
    selfHeal: true
```

### 예시: cert-manager 전환

```bash
# 1. 현재 values 확인
helm get values cert-manager -n cert-manager > current-values.yaml

# 2. Git의 values.yaml과 비교
diff current-values.yaml git-ops/infra/cert-manager/values.yaml

# 3. 필요시 Git의 values.yaml 수정하여 현재 상태와 일치시키기

# 4. Application 생성
kubectl apply -f git-ops/infra/cert-manager/application.yaml

# 5. Argo CD에서 상태 확인
kubectl get application cert-manager -n argo-cd
```

이제 모든 변경사항은 Git을 통해 관리됩니다.
