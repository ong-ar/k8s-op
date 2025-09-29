# install

```bash
# Ubuntu / Debian
sudo apt update && sudo apt install -y open-iscsi

# CentOS / RHEL
sudo yum install -y iscsi-initiator-utils

sudo systemctl enable iscsid
sudo systemctl start iscsid

sudo modprobe iscsi_tcp

# 권장
sudo systemctl stop multipathd
sudo systemctl disable multipathd
```

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
