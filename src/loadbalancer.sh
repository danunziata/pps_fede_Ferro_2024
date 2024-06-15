#!/bin/bash

if [ "$#" -lt 2 ]; then
    exit 1
fi

kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.14.5/config/manifests/metallb-native.yaml

mkdir tmp

{
  cat <<EOF
apiVersion: metallb.io/v1beta1
kind: IPAddressPool
metadata:
  name: $1
  namespace: metallb-system
spec:
  addresses:
EOF
  for arg in "${@:2}"; do
      echo "  - $arg"
  done
} > tmp/pool.yaml

{
  cat <<EOF
apiVersion: metallb.io/v1beta1
kind: L2Advertisement
metadata:
  name: $1
  namespace: metallb-system
EOF
} > tmp/announce.yaml

kubectl rollout status deployment controller -n metallb-system  --timeout=120s > /dev/null 2>&1

kubectl apply -f tmp/pool.yaml

kubectl apply -f tmp/announce.yaml

rm -rf tmp