#!/bin/bash

# Define variables
NAMESPACE="loki"
VALUES_FILE="values/lokistack-values.yaml"

echo -e "This might take a few minutes...\n"

# Add Helm repo and update
{
    helm repo add grafana https://grafana.github.io/helm-charts
    helm repo update

    # Create Kubernetes namespace
    kubectl create namespace $NAMESPACE

    # Install/upgrade Loki stack
    helm upgrade --install loki grafana/loki-stack --namespace=$NAMESPACE --values $VALUES_FILE

    # Wait for the Loki Grafana deployment to be ready
    kubectl rollout status deployment loki-grafana -n $NAMESPACE --timeout=210s
} > /dev/null 2>&1

# Check if the previous block executed successfully
if [ $? -eq 0 ]; then
    echo -e "The Loki stack has been deployed to your cluster. Loki can now be added as a datasource in Grafana."
else
    echo -e "An error occurred during the deployment of the Loki stack. Please check the logs for more details."
    exit 1
fi

# Retrieve and display Grafana admin password
echo -e "Admin's Password"
kubectl get secret loki-grafana --namespace=$NAMESPACE -o jsonpath="{.data.admin-password}" | base64 --decode ; echo

# Instructions to access Grafana service
echo -e "\nTo access the Grafana service, open a new terminal and execute the following command:"
echo "kubectl port-forward --namespace $NAMESPACE service/loki-grafana 3000:80"
echo -e "\nThen, open your browser and go to:"
echo "http://localhost:3000"
