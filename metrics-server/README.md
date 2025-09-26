# install

```bash
helm repo add metrics-server https://kubernetes-sigs.github.io/metrics-server/
helm repo update
```

```bash
helm install metrics-server metrics-server/metrics-server \
  --version 3.12.2 \
  -n kube-system \
  -f values.yaml
```
