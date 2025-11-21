# install

## commands

```bash
helm repo add bakito https://charts.bakito.net
helm repo update
```

```bash
helm upgrade --install sealed-secrets-web bakito/sealed-secrets-web \
  -n sealed-secrets-web --create-namespace \
  -f values.yaml
```
