# install

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

```bash
# Operator 상태 확인
kubectl get pods -n tigera-operator

# Calico core 컴포넌트 상태 확인
kubectl get pods -n calico-system -o wide

# CRD 리소스 확인
kubectl get ippools.crd.projectcalico.org

# node ready
kubectl get nodes -o wide
```
