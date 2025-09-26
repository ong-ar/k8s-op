# install

```bash
helm repo add metallb https://metallb.github.io/metallb
helm repo update
```

```bash
helm install metallb metallb/metallb \
  --version 0.15.2 \
  -n metallb-system --create-namespace

helm install metallb-config ./config-chart -n metallb-system
```
