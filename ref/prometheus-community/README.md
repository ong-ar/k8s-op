# install

## values

- [Link](https://github.com/prometheus-community/helm-charts/tree/kube-prometheus-stack-77.11.1/charts/kube-prometheus-stack)

## commands

```bash
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
```

```bash
helm upgrade --install kube-prometheus-stack prometheus-community/kube-prometheus-stack \
  --version 79.5.0 \
  -n monitoring --create-namespace \
  -f values.yaml

helm upgrade kube-prometheus-stack prometheus-community/kube-prometheus-stack \
  --version 79.5.0 \
  -n monitoring --create-namespace \
  -f values.yaml

helm uninstall kube-prometheus-stack -n monitoring

kubectl apply -f ingress.yaml
```

```bash
kubectl get svc -n monitoring
```
