# install

```bash
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
```

```bash
helm install monitoring prometheus-community/kube-prometheus-stack \
  --version 77.11.1 \
  -n kube-system --create-namespace \
  -f values.yaml
```

```bash
kubectl get svc -n monitoring
```
