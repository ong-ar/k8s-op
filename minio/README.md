# install

## values

- [Link](https://docs.min.io/community/minio-object-store/operations/deployments/k8s-deploy-minio-tenant-on-kubernetes.html)

## commands

```bash
helm repo add minio-operator https://operator.min.io
helm repo update
```

```bash
helm install minio-operator minio-operator/operator \
  --version 7.1.1 \
  -n minio-operator --create-namespace

helm install tenant-loki minio-operator/tenant \
   --version 7.1.1 \
  -n tenant-loki --create-namespace \
  -f tenant_values.yaml
```

```bash
kubectl get pods -n minio-operator

kubectl get pods -n tenant-loki
kubectl get pvc -n tenant-loki
kubectl get svc -n tenant-loki
```
