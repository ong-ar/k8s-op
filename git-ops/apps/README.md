# GitOps Applications (Services)

이 디렉토리는 서비스 애플리케이션(`service-a`, `service-b`)의 배포 설정을 관리합니다.

## 1. 사전 요구사항 (Prerequisites)

클러스터에 다음 구성 요소가 설치되어 있어야 합니다.

- **ArgoCD**: 애플리케이션 배포 도구
- **Sealed Secrets Controller**: 암호화된 Secret 관리 도구 (`kube-system` 네임스페이스)
- **Ingress Controller**: (예: Nginx Ingress) 서비스 외부 노출용

## 2. AppProject 등록

애플리케이션들을 관리할 ArgoCD Project(`services`)를 먼저 등록해야 합니다.

```bash
kubectl apply -f git-ops/apps/app-project.yaml
```

## 3. 애플리케이션 등록

각 서비스를 ArgoCD에 등록합니다. 이 작업은 최초 1회만 수행하면 되며, 이후에는 GitOps 방식(Git 변경 감지)으로 자동 관리됩니다.

```bash
# Service A 등록
kubectl apply -f git-ops/apps/service-a/application.yaml

# Service B 등록
kubectl apply -f git-ops/apps/service-b/application.yaml
```

등록 후 ArgoCD UI에서 `service-a`와 `service-b` 애플리케이션이 생성된 것을 확인할 수 있습니다.

## 4. 환경변수 설정 (Sealed Secrets)

각 서비스는 `.env` 파일을 필요로 합니다. 보안을 위해 Sealed Secrets를 사용하여 암호화된 형태로 Git에 저장합니다.

**주의:** `kubeseal` CLI가 설치되어 있고, 클러스터에 접근 가능한 상태여야 합니다.

### Service A Secret 생성

```bash
# 1. .env 파일 생성 (실제 값 입력)
echo 'MESSAGE="Hello from Service A"' > .env.service-a

# 2. Sealed Secret 생성 (namespace: production)
kubectl create secret generic service-a-env-secret \
  --from-file=.env=.env.service-a \
  --namespace production \
  --dry-run=client -o yaml | \
  kubeseal --controller-name=sealed-secrets --controller-namespace=kube-system --format=yaml > git-ops/apps/service-a/resources/sealed-secret.yaml

# 3. 임시 파일 삭제
rm .env.service-a
```

### Service B Secret 생성

```bash
# 1. .env 파일 생성
echo 'MESSAGE="Hello from Service B"' > .env.service-b

# 2. Sealed Secret 생성 (namespace: production)
kubectl create secret generic service-b-env-secret \
  --from-file=.env=.env.service-b \
  --namespace production \
  --dry-run=client -o yaml | \
  kubeseal --controller-name=sealed-secrets --controller-namespace=kube-system --format=yaml > git-ops/apps/service-b/resources/sealed-secret.yaml

# 3. 임시 파일 삭제
rm .env.service-b
```

생성된 `sealed-secret.yaml` 파일을 커밋하고 푸시하면 ArgoCD가 자동으로 적용합니다.

## 5. 배포 프로세스 (CI/CD)

### 수동 빌드 및 배포

GitHub Actions의 `Build and Push` 워크플로우는 **수동 트리거(`workflow_dispatch`)** 방식으로 설정되어 있습니다.

1.  GitHub Repository -> **Actions** 탭 이동
2.  **Build and Push** 워크플로우 선택
3.  **Run workflow** 버튼 클릭
    - Branch: `main`
    - Service: `all` (전체) 또는 특정 서비스 선택
4.  **실행 결과**:
    - Docker 이미지 빌드 및 GHCR 푸시
    - Git 리포지토리의 `kustomization.yaml` 내 이미지 태그 업데이트 (자동 커밋)
    - ArgoCD가 변경 사항 감지 후 클러스터에 자동 배포
