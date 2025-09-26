# repo

```bash
helm repo add projectcalico https://projectcalico.docs.tigera.io/charts
helm repo update
```

```bash
helm install calico projectcalico/tigera-operator \
  --version 3.30.3 \
  -n tigera-operator --create-namespace \
  -f values.yaml
```
