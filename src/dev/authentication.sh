#!/bin/bash

helm repo add authentik https://charts.goauthentik.io
helm repo update
helm upgrade --install authentik authentik/authentik -f values/authentik-values.yaml

export POD_AUTHENTIK=$(kubectl get pods -l "app.kubernetes.io/component=server" -o jsonpath="{.items[0].metadata.name}")

echo -e "This might take a few minutes...\n"

sleep 210
kubectl wait --for='jsonpath={.status.conditions[?(@.type=="Ready")].status}=True' pod/$POD_AUTHENTIK

echo -e "\n"
kubectl label pod $POD_AUTHENTIK app=authentik
kubectl apply -f services/authentik-service.yaml
minikube service authentik-service