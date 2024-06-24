#!/bin/bash

default(){
    multipass find --force-update > /dev/null 2>&1
    multipass launch jammy --cpus 2 --memory 3G --disk 5G --name master-node --cloud-init ~/cluster/multipass.yaml
    sleep 5
    export MULTIPASSIP=`multipass info master-node | grep IP | grep -oE '[^ ]+$'`
    sleep 2
}

default2(){
    export KUBECONFIG=$PWD/kubeconfig
    kubectl config use-context default
    kubectl get node -o wide
}

echo -e "\nYou are installing k3s with multipass and k3sup..."
echo -e "\nPlease select one of the following options"
echo -e "\n[1] Default"
echo -e "[2] Disable ServiceLB"
echo -e "[3] Disable Traefik"
echo -e "[4] Disable both"
echo -e "\n"

valid_option=false

while [ "$valid_option" == false ]; do
    read -p "Option: " option

    case $option in
        1)
            default
            k3sup install --ip $MULTIPASSIP --user ubuntu --k3s-extra-args "--cluster-init" --local-path ~/config/kubeconfig
            default2
            valid_option=true
            ;;
        2)
            default
            k3sup install --ip $MULTIPASSIP --user ubuntu --k3s-extra-args "--cluster-init --disable=servicelb" --local-path ~/config/kubeconfig
            default2
            valid_option=true
            ;;
        3)
            default
            k3sup install --ip $MULTIPASSIP --user ubuntu --k3s-extra-args "--cluster-init --disable=traefik" --local-path ~/config/kubeconfig
            default2
            valid_option=true
            ;;
        4)
            default
            k3sup install --ip $MULTIPASSIP --user ubuntu --k3s-extra-args "--cluster-init --disable=traefik,servicelb" --local-path ~/config/kubeconfig
            default2
            valid_option=true
            ;;
        *)
            echo -e "Invalid Option. Please try again."
            ;;
    esac
done