# Reflector 수동 설치 가이드

## 1. Helm Repository 추가
```bash
helm repo add emberstack https://emberstack.github.io/helm-charts
helm repo update
```

## 2. 설치
```bash
helm upgrade --install reflector emberstack/reflector \
  --version 9.1.40 \
  --namespace kube-system \
  --create-namespace \
  -f values.yaml
```

## 3. 확인
```bash
kubectl get pods -n kube-system -l app.kubernetes.io/name=reflector
```

## 4. 사용법
원본 Secret/ConfigMap에 다음 Annotation을 추가하면 자동으로 복제됩니다.

```yaml
metadata:
  annotations:
    # 모든 네임스페이스로 복제
    reflector.v1.k8s.emberstack.com/reflection-allowed: "true"
    reflector.v1.k8s.emberstack.com/reflection-allowed-namespaces: ""
    
    # 또는 특정 네임스페이스로만 복제
    # reflector.v1.k8s.emberstack.com/reflection-allowed: "true"
    # reflector.v1.k8s.emberstack.com/reflection-allowed-namespaces: "argo-cd,longhorn-system"
```

