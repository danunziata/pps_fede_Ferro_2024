#!/bin/bash
echo -e "\n"
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update

minikube start --driver=kvm2
kubectl create namespace loki
helm upgrade --install loki grafana/loki-stack --namespace=loki --values values-loki-stack.yaml
echo -e "\n"
echo -e "This might take a few minutes...\n"
sleep 120
kubectl get all -n loki
echo -e "\nAdmin's Password"
kubectl get secret loki-grafana --namespace=loki -o jsonpath="{.data.admin-password}" | base64 --decode ; echo
echo -e "\nTo access the grafana's service, you need to open a new terminal and execute the following command:"
echo "kubectl port-forward --namespace loki service/loki-grafana 3000:80"
echo -e "\nhttp::/localhost:3000"
