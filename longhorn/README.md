# install

```bash
helm repo add longhorn https://charts.longhorn.io
helm repo update
```

```bash
helm install longhorn longhorn/longhorn \
  --namespace longhorn-system --create-namespace \
  --version 1.10.0
  -f values.yaml

helm upgrade longhorn longhorn/longhorn \
  --namespace longhorn-system \
  --version 1.10.0 \
  -f values.yaml
```

```bash
kubectl get pvc -n monitoring

kubectl get pv | grep longhorn

kubectl -n longhorn-system get pods
kubectl get storageclass

# 사용량 확인
kubectl -n monitoring exec -it <prometheus-pod-name> -- df -h /prometheus

kubectl -n monitoring exec -it <grafana-pod-name> -- df -h /var/lib/grafana

kubectl -n monitoring exec -it <alertmanager-pod-name> -- df -h /alertmanager

kubectl get svc -n longhorn-system
```
