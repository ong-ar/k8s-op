# install

## values

- [Link](https://github.com/prometheus-community/helm-charts/tree/kube-prometheus-stack-77.11.1/charts/kube-prometheus-stack)

## commands

```bash
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
```

```bash
helm install kube-prometheus-stack prometheus-community/kube-prometheus-stack \
  --version 77.11.1 \
  -n monitoring --create-namespace \
  -f values.yaml

helm upgrade kube-prometheus-stack prometheus-community/kube-prometheus-stack \
  --version 77.11.1 \
  -n monitoring --create-namespace \
  -f values.yaml

helm uninstall
```

```bash
kubectl get svc -n monitoring
```
