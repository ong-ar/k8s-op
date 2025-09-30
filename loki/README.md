# install

## values

- [Link](https://grafana.com/docs/loki/latest/setup/install/helm/install-monolithic/)

## commands

```bash
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update
```

```bash
helm install loki grafana/loki \
  --version 6.41.1 \
  -n monitoring --create-namespace \
  -f values.yaml

helm upgrade loki grafana/loki \
  --version 6.41.1 \
  -n monitoring --create-namespace \
  -f values.yaml
```

```bash

```
