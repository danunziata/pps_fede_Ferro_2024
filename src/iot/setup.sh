#!/bin/bash

minikube delete

minikube start --driver=kvm2 --static-ip 192.168.39.44

eval $(minikube docker-env)

docker build -t mocksensor mocksensor

kubectl apply -f pvc.yaml

kubectl apply -f secret.yaml

export MINIKUBEIP=$(minikube ip)

sleep 2

envsubst < configmap.yaml | kubectl apply -f -

kubectl apply -f service.yaml

sleep 2

kubectl apply -f deployment.yaml