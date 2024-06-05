#!/bin/bash

multipass find --force-update   

clear

multipass launch jammy --cpus 2 --memory 2G --disk 5G --name master-node --cloud-init ~/cluster/multipass.yaml

sleep 2

export MULTIPASSIP=`multipass info master-node | grep IP | grep -oE '[^ ]+$'` 

sleep 2

k3sup install --ip $MULTIPASSIP --user ubuntu --k3s-extra-args "--cluster-init --disable=servicelb"

export KUBECONFIG=$PWD/kubeconfig

kubectl config use-context default

kubectl get node -o wide
