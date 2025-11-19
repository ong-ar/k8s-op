# install

## commands

```bash
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update
```

```bash
helm upgrade --install ingress-nginx ingress-nginx/ingress-nginx \
  --namespace ingress-nginx \
  --create-namespace \
  --version 4.14.0 \
  -f values.yaml
```

```bash
kubectl get pods -n ingress-nginx -o wide
kubectl get ds -n ingress-nginx
```
