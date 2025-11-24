# install

## commands

```bash
helm repo add cert-manager https://charts.jetstack.io
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
# namespace가 없으면 먼저 생성
kubectl create namespace cert-manager --dry-run=client -o yaml | kubectl apply -f -

# Secret 생성
kubectl create secret generic gcp-dns-key \
  --namespace cert-manager \
  --dry-run=client -o yaml \
  --from-file=key.json=../key.json \
  | kubectl apply -f -
```
