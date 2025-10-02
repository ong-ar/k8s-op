# install

## values

- [Link](https://github.com/argoproj/argo-helm/blob/main/charts/argo-cd/values.yaml)

## commands

```bash
helm repo add argo https://argoproj.github.io/argo-helm
helm repo update
```

```bash
helm install argocd argo/argo-cd \
  --version 8.5.8 \
  -n argo-cd --create-namespace \
  -f values.yaml

helm upgrade argocd argo/argo-cd \
  --version 8.5.8 \
  -n argo-cd --create-namespace \
  -f values.yaml
```

```bash
kubectl get pods -n argo-cd

kubectl get pods -n argo-cd -o wide
```
