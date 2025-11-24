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
helm install -n argocd  # Argo CD가 argocd namespace에 설치됨
```

**2. AppProject/Application 만들 때:**

```yaml
metadata:
  namespace: argocd # 반드시 위와 같은 namespace (argocd)
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

- `helm install -n argocd` = `metadata.namespace: argocd` (둘 다 `argocd`로 통일)
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

1. Git에 현재 상태 커밋
2. Application 생성
3. Argo CD가 자동으로 동기화

이제 모든 변경사항은 Git을 통해 관리됩니다.
