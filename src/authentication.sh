#!/bin/bash

# Define variables
VALUES_FILE="values/authentik-values.yaml"
DEPLOYMENT_NAME="authentik-server"
POD_LABEL="app.kubernetes.io/component=server"
NEW_POD_LABEL="app=authentik"

echo -e "\nThe installation has started..."
echo -e "This might take a few minutes..."

# Add Helm repo and update
{
    helm repo add authentik https://charts.goauthentik.io
    helm repo update

    # Install/upgrade Authentik
    helm upgrade --install authentik authentik/authentik -f $VALUES_FILE

    # Wait for the Authentik server deployment to be ready
    kubectl rollout status deployment $DEPLOYMENT_NAME --timeout=600s

    # Get the Authentik server pod name
    POD_AUTHENTIK=$(kubectl get pods -l "$POD_LABEL" -o jsonpath="{.items[0].metadata.name}")
    export POD_AUTHENTIK

    # Wait until the pod is ready
    sleep 2
    kubectl wait --for='jsonpath={.status.conditions[?(@.type=="Ready")].status}=True' pod/$POD_AUTHENTIK

    # Label the pod and apply the service configuration
    kubectl label pod $POD_AUTHENTIK $NEW_POD_LABEL
    kubectl apply -f services/authentik-service.yaml
} > /dev/null 2>&1

# Check if the previous block executed successfully
if [ $? -eq 0 ]; then
    echo -e "Process completed successfully!"
else
    echo -e "An error occurred during the installation process. Please check the logs for more details."
    exit 1
fi
