#!/bin/bash

manifests=./manifests
tmp_file=/tmp/manifest-$RANDOM.yaml

[ -d "$manifests" ] || (echo "manifests dir not found" && exit 1)

kubectl create -f $manifests/
oc adm policy add-scc-to-user privileged system:serviceaccount:storageos:storageos
sleep 2

CLUSTER_IP=$(kubectl -n storageos get svc/storageos -o custom-columns=IP:spec.clusterIP --no-headers=true)
API_ADDRESS=$(echo -n "tcp://$CLUSTER_IP:5705" | base64)
JOIN=$(kubectl get nodes -l node-role.kubernetes.io/compute=true -o  jsonpath='{ $.items[*].status.addresses[?(@.type=="InternalIP")].address  }' |tr ' ' ',';echo)

sed -e "s/<API_ADDRESS>/$API_ADDRESS/" "$manifests/030_interface.yaml_template" >> "$tmp_file"
echo "---" >> "$tmp_file"
sed -e "s/<JOIN>/$JOIN/" "$manifests/040_daemonset.yaml_template" >> "$tmp_file"

kubectl create -f $tmp_file

GR='\033[0;32m'
NC='\033[0m' # No Color
echo -e "${GR}Checkout status: kubectl -n storageos get pods${NC}"
