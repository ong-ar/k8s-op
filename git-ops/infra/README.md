# Infrastructure GitOps

Argo CD로 관리하는 인프라 컴포넌트들입니다.

## 구조

```
git-ops/infra/
├── app-project.yaml          # AppProject 정의 (infra-structure)
├── calico/
│   ├── application.yaml      # Helm chart 설치 + resources 관리
│   ├── kustomization.yaml
│   └── resources/
├── ingress-nginx/
│   ├── application.yaml      # Helm chart 설치 + resources 관리
│   └── kustomization.yaml
├── sealed-secrets/
│   ├── application.yaml      # Helm chart 설치 + resources 관리
│   ├── kustomization.yaml
│   └── resources/
│       └── create-secret-key.yaml
├── cert-manager/
│   ├── application.yaml      # Helm chart 설치 + resources 관리
│   ├── kustomization.yaml
│   └── resources/
│       ├── create-secret-key-json.yaml
│       ├── cluster-issuer.yaml
│       └── wildcard-certificate.yaml
├── reflector/
│   ├── application.yaml      # Helm chart 설치 (리소스 동기화)
│   └── kustomization.yaml
├── argo-cd/
│   ├── application.yaml      # Helm chart 설치 + resources 관리
│   ├── kustomization.yaml
│   └── resources/
│       └── ingress.yaml
├── longhorn/
│   ├── application.yaml      # Helm chart 설치 + resources 관리
│   ├── kustomization.yaml
│   └── resources/
│       └── ingress.yaml
├── metrics-server/
│   ├── application.yaml      # Helm chart 설치 + resources 관리
│   └── kustomization.yaml
├── prometheus-community/
│   ├── application.yaml      # Helm chart 설치 + resources 관리
│   ├── kustomization.yaml
│   └── resources/
│       └── ingress.yaml
├── minio/
│   ├── application.yaml      # minio-operator + minio-tenant (2개 Application)
│   ├── kustomization.yaml
│   └── resources/
├── loki/
│   ├── application.yaml      # loki + promtail (2개 Application)
│   ├── kustomization.yaml
│   └── resources/
└── sealed-secrets-web/
    ├── application.yaml      # Helm chart 설치 + resources 관리
    ├── kustomization.yaml
    └── resources/
        └── ingress.yaml
```

**구조 설명:**

- `application.yaml`: Argo CD Application manifest
  - **Argo CD 2.6+ Multiple Sources** 사용: Helm repository (chart 설치) + Git repository (resources 관리)
  - Helm chart 설치와 Kubernetes resources를 함께 관리
- `kustomization.yaml`: Kustomize 설정 (resources 폴더의 YAML 파일들 참조)
- `resources/`: Kubernetes 리소스 YAML 파일들 (Ingress, Certificate, Secret 등)

**중요**: 모든 컴포넌트는 **Argo CD가 Helm chart 설치와 resources를 함께 관리**합니다.

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
# Bootstrap 컴포넌트들 (의존성 순서대로)
kubectl apply -f git-ops/infra/calico/application.yaml
kubectl apply -f git-ops/infra/ingress-nginx/application.yaml
kubectl apply -f git-ops/infra/sealed-secrets/application.yaml
kubectl apply -f git-ops/infra/cert-manager/application.yaml
kubectl apply -f git-ops/infra/reflector/application.yaml

# Argo CD 자체 (이미 설치된 경우 선택적)
kubectl apply -f git-ops/infra/argo-cd/application.yaml

# 추가 인프라 컴포넌트들
kubectl apply -f git-ops/infra/longhorn/application.yaml
kubectl apply -f git-ops/infra/metrics-server/application.yaml
kubectl apply -f git-ops/infra/prometheus-community/application.yaml
kubectl apply -f git-ops/infra/minio/application.yaml
kubectl apply -f git-ops/infra/loki/application.yaml
kubectl apply -f git-ops/infra/sealed-secrets-web/application.yaml
```

또는 한 번에:

```bash
find git-ops/infra -name "application.yaml" -exec kubectl apply -f {} \;
```

## Git Repository URL 설정

모든 Application manifest에서 Git repository URL이 올바르게 설정되어 있는지 확인하세요:

```bash
# 현재 설정 확인
grep -r "repoURL.*github.com" git-ops/infra/*/application.yaml

# 필요시 수정
find git-ops/infra -name "application.yaml" -exec sed -i '' 's|https://github.com/ong-ar/k8s-op|https://github.com/your-org/k8s-op|g' {} \;
```

## 관리 방식

### Argo CD가 Helm Chart와 Resources를 함께 관리

**원칙**:

- **Argo CD 2.6+ Multiple Sources** 기능 사용
- Helm repository에서 Helm chart 설치
- Git repository에서 Kubernetes resources 관리
- 모든 컴포넌트를 Argo CD가 통합 관리

### 컴포넌트별 관리 내용

| 컴포넌트                 | Helm Chart 설치          | Argo CD 관리 Resources                                           | Namespace          |
| ------------------------ | ------------------------ | ---------------------------------------------------------------- | ------------------ |
| **calico**               | ✅ tigera-operator       | resources 없음 (현재)                                            | tigera-operator    |
| **ingress-nginx**        | ✅ ingress-nginx         | resources 없음 (현재)                                            | ingress-nginx      |
| **sealed-secrets**       | ✅ sealed-secrets        | create-secret-key.yaml                                           | sealed-secrets     |
| **cert-manager**         | ✅ cert-manager          | create-secret-key-json.yaml, ClusterIssuer, wildcard-certificate | cert-manager       |
| **reflector**            | ✅ reflector             | resources 없음                                                   | kube-system        |
| **argo-cd**              | ✅ argo-cd               | ingress.yaml                                                     | argo-cd            |
| **longhorn**             | ✅ longhorn              | ingress.yaml                                                     | longhorn-system    |
| **metrics-server**       | ✅ metrics-server        | resources 없음                                                   | kube-system        |
| **prometheus-community** | ✅ kube-prometheus-stack | ingress.yaml                                                     | monitoring         |
| **minio-operator**       | ✅ operator              | resources 없음                                                   | minio-operator     |
| **minio-tenant**         | ✅ tenant                | resources 없음                                                   | tenant-loki        |
| **loki**                 | ✅ loki                  | resources 없음                                                   | loki               |
| **promtail**             | ✅ promtail              | resources 없음                                                   | loki               |
| **sealed-secrets-web**   | ✅ sealed-secrets-web    | ingress.yaml                                                     | sealed-secrets-web |

### 실행 순서 보장 (cert-manager)

Argo CD에서 관리하는 resources:

- **Wave 1**: ClusterIssuer 생성 (annotation: `argocd.argoproj.io/sync-wave: "1"`)
- **Wave 2**: Certificate 생성 (annotation: `argocd.argoproj.io/sync-wave: "2"`)

sync-waves를 사용하여 실행 순서를 보장합니다.

### 인증서 관리 전략 (Certificate Sync)

우리는 **Reflector**를 사용하여 단일 와일드카드 인증서를 모든 네임스페이스로 복제하여 사용합니다.

1. **cert-manager**: `cert-manager` 네임스페이스에 `wildcard-certificate.yaml` 배포
2. **reflector**: `reflection.emberstack.com/reflection-auto-enabled: "true"` 어노테이션을 감지하여 Secret(`archainia-wildcard-tls`)을 모든 네임스페이스로 자동 복제
3. **사용**: 각 Application의 Ingress는 복제된 Secret을 참조하여 HTTPS 적용

> **참고**: 특정 네임스페이스에만 복제하려면 `reflection-allowed: "true"` 및 `reflection-allowed-namespaces: "argo-cd,longhorn-system"` 설정을 사용합니다. 현재는 관리 편의를 위해 전체 복제 방식을 사용 중입니다.

## 주의사항

1. **Git Repository URL**:

   - 모든 Application에서 Git repository URL이 올바르게 설정되어 있는지 확인하세요

2. **Secret 파일**:

   - `sealed-secrets/resources/create-secret-key.yaml`의 `tls.crt`, `tls.key` 값을 입력해야 합니다
   - `cert-manager/resources/create-secret-key-json.yaml`은 SealedSecret이므로 이미 암호화되어 있습니다

3. **application.yaml 제외**:

   - 각 디렉토리의 `kustomization.yaml`에서 `application.yaml`을 제외하여 중복 실행을 방지합니다

4. **의존성**:

   - cert-manager는 sealed-secrets 이후에 배포되어야 합니다 (GCP DNS Key Secret 필요)
   - Argo CD Ingress는 cert-manager와 ingress-nginx 이후에 배포되어야 합니다
   - minio-tenant는 minio-operator 이후에 배포되어야 합니다
   - loki는 minio-tenant 이후에 배포되어야 합니다 (S3 backend 사용)
   - promtail는 loki 이후에 배포되어야 합니다

5. **수동 동기화**:
   - 모든 Application은 `syncPolicy.automated`가 없어서 수동 동기화입니다
   - Application 생성 후 Argo CD UI에서 수동으로 Sync를 실행해야 합니다

## Bootstrap에서 전환하기

Bootstrap으로 설치한 컴포넌트를 Argo CD로 전환하는 방법:

### 방법 1: Sync 없이 Kustomization만 (리소스 생성만)

수동으로 설치한 컴포넌트를 Argo CD로 전환하되, **실제 sync(배포)는 하지 않고** kustomization(리소스 생성/관리)까지만 하고 싶을 때:

#### 설정 방법

Application의 `syncPolicy`를 제거하거나 `automated`를 끄면 됩니다:

```yaml
# syncPolicy 제거 또는 automated 없이
spec:
  syncPolicy:
    # automated 필드 없음 = 수동 동기화만
    syncOptions:
      - CreateNamespace=true
```

#### 동작 방식

1. **Application 생성**: Argo CD가 Application 리소스를 생성
2. **Kustomization 빌드**: Git에서 `kustomization.yaml`을 읽어 resources 목록 생성
   - `kustomization.yaml`의 `resources`에 정의된 파일들을 빌드
   - 실제로는 리소스 YAML 목록만 생성 (아직 클러스터에 적용 안 됨)
3. **Sync 여부**:
   - `syncPolicy.automated`가 없으면 **자동 sync 안 함**
   - 하지만 Application이 처음 생성될 때는 기본적으로 **한 번 sync를 시도**할 수 있음
   - 수동으로 sync하지 않으면 리소스가 클러스터에 생성되지 않음
4. **상태 모니터링**: Argo CD가 Git 상태와 클러스터 상태를 비교만 함

#### 예시: cert-manager 전환 (Resources만 관리)

```bash
# 1. cert-manager Helm chart는 이미 수동 설치되어 있다고 가정
# (Bootstrap 단계에서 설치됨)

# 2. Application 생성 (Helm chart + resources 관리)
kubectl apply -f git-ops/infra/cert-manager/application.yaml

# 3. 상태 확인
kubectl get application cert-manager -n argo-cd

# 4. 상태 확인 (OutOfSync 상태일 수 있음, 정상)
kubectl get application cert-manager -n argo-cd

# 5. 수동 sync 실행 (리소스가 클러스터에 생성됨)
# Argo CD UI에서 Sync 버튼 클릭 또는
argocd app sync cert-manager

# 6. 리소스 확인 (sync 후 생성됨)
kubectl get clusterissuer
kubectl get certificate -n argo-cd
```

**참고**: cert-manager Application은 Helm chart와 resources(ClusterIssuer, Certificate 등)를 모두 관리합니다.

**장점**:

- 기존 수동 설치 유지 가능 (values가 일치하는 경우)
- Git에서 리소스 정의만 관리
- 필요할 때만 수동으로 sync

---

### 방법 2: 완전 전환 (Sync 포함)

수동 설치를 완전히 Argo CD로 전환하려면:

#### 1. 현재 설치 상태 확인

```bash
# 예: cert-manager의 현재 values 확인
helm get values cert-manager -n cert-manager

# 예: ingress-nginx의 현재 values 확인
helm get values ingress-nginx -n ingress-nginx
```

#### 2. Git의 application.yaml values와 일치시키기

**중요**: Git에 있는 `application.yaml`의 `helm.values`가 현재 설치된 상태와 **일치**해야 합니다.

- 현재 설치된 values와 다르면 → Git의 `application.yaml`의 `helm.values`를 현재 상태에 맞게 수정
- 또는 현재 설치된 상태를 Git의 values에 맞게 변경 (권장하지 않음)

#### 3. Application 생성

```bash
kubectl apply -f git-ops/infra/<component>/application.yaml
```

#### 4. Argo CD 동작 확인

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

#### 주의사항

⚠️ **자동 동기화 주의**:

- `syncPolicy.automated`가 켜져 있으면 Git 상태와 다를 때 자동으로 변경됩니다
- 처음 전환할 때는 `automated`를 잠시 끄고, 상태 확인 후 켜는 것을 권장합니다

```yaml
# 처음 전환 시 (수동 확인용)
syncPolicy:
  # automated 필드를 제거하면 수동 동기화
  syncOptions:
    - CreateNamespace=true

# 상태 확인 후 (자동 동기화 활성화)
syncPolicy:
  automated:
    prune: true
    selfHeal: true
  syncOptions:
    - CreateNamespace=true
```

#### 예시: cert-manager 전환 (완전 전환)

```bash
# 1. 현재 values 확인
helm get values cert-manager -n cert-manager > current-values.yaml

# 2. Git의 application.yaml의 helm.values와 비교
# (application.yaml에서 helm.values 부분 확인)

# 3. 필요시 Git의 application.yaml의 helm.values 수정하여 현재 상태와 일치시키기

# 4. Application 생성
kubectl apply -f git-ops/infra/cert-manager/application.yaml

# 5. Argo CD에서 상태 확인
kubectl get application cert-manager -n argo-cd

# 6. 수동 sync (automated가 없으면)
argocd app sync cert-manager
```

이제 모든 변경사항은 Git을 통해 관리됩니다.
