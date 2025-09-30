# install

## values

- [Link](https://github.com/metallb/metallb/tree/v0.15.2/charts/metallb)

## commands

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

```bash
kubectl get pods -n metallb-system -o wide

# config
helm list -n metallb-system

kubectl get ipaddresspools.metallb.io -n metallb-system
# response
# NAME                   AUTO ASSIGN   AVOID BUGGY IPS   ADDRESSES
# default-address-pool   true          false             ["192.168.2.100-192.168.2.200"]

kubectl get l2advertisements.metallb.io -n metallb-system
# response
# NAME         IPADDRESSPOOLS             IPADDRESSPOOL SELECTORS   INTERFACES
# default-l2   ["default-address-pool"]

# test
kubectl create deploy nginx --image=nginx --port=80
kubectl expose deploy nginx --port=80 --type=LoadBalancer
kubectl get svc nginx

# delete test
kubectl delete deploy nginx
kubectl delete svc nginx

kubectl get deploy nginx
kubectl get svc nginx
```
