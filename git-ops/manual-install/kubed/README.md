# Kubed 수동 설치 가이드

## 1. Helm Repository 추가
```bash
helm repo add appscode https://charts.appscode.com/stable/
helm repo update
```

## 2. 설치
```bash
helm upgrade --install kubed appscode/kubed \
  --version v0.13.2 \
  --namespace kubed \
  --create-namespace \
  -f values.yaml
```

## 3. 확인
```bash
kubectl get pods -n kubed
```

