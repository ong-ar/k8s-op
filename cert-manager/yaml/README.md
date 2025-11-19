# Install

```
kubectl apply -f create-cluster-issuer-archainia.yaml

kubectl apply -f certificate-archainia.yaml -n longhorn-system
kubectl apply -f certificate-archainia.yaml -n monitoring
kubectl apply -f certificate-archainia.yaml -n argo-cd
kubectl apply -f certificate-archainia.yaml -n ingress-demo
kubectl apply -f certificate-archainia.yaml -n ingress-demo
kubectl apply -f certificate-archainia.yaml -n ingress-demo
kubectl apply -f certificate-archainia.yaml -n ingress-demo
```

# Check

```
kubectl get clusterissuer
kubectl describe clusterissuer letsencrypt-issuer-archainia-app


kubectl get certificate -n ingress-demo
kubectl describe certificate archainia-wildcard-cert -n ingress-demo
kubectl get secret archainia-wildcard-tls -n ingress-demo
```
