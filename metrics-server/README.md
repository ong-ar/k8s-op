# install

```bash
helm repo add metrics-server https://kubernetes-sigs.github.io/metrics-server/
helm repo update
```

```bash
helm install metrics-server metrics-server/metrics-server \
  --version 3.12.2 \
  -n kube-system --create-namespace \
  -f values.yaml
```

```bash
kubectl get pods -n kube-system -l app.kubernetes.io/name=metrics-server -o wide

# 현재 values 확인
helm get values metrics-server -n kube-system

# Deployment args 확인
kubectl -n kube-system get deploy metrics-server -o yaml | grep -A5 args:
```
