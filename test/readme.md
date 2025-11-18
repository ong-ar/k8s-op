kubectl apply -f namespace.yaml
kubectl apply -f apps.yaml
kubectl -n ingress-demo get pods,svc

kubectl apply -f ingress-hosts.yaml
kubectl -n ingress-demo get ingress

curl -H "Host: app1.dev.example.com" http://34.71.130.29/
curl -H "Host: app2.dev.example.com" http://34.71.130.29/
curl -H "Host: admin.dev.example.com" http://34.71.130.29/
