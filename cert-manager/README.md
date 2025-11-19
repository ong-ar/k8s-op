# install

## commands

```bash
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update
```

```bash
helm upgrade --install cert-manager jetstack/cert-manager \
  --namespace cert-manager \
  --create-namespace \
  --version 1.19.1 \
  -f values.yaml
```

```bash
kubectl get pods -n cert-manager

# secret 생성 (gcloud)
kubectl create secret generic gcp-dns-key \
  --namespace cert-manager \
  --dry-run=client -o yaml \
  --from-file=key.json=./gcp-service-key-dns.json \
  | kubectl apply -f -
```
