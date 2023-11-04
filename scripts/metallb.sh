#!/bin/bash

if [ "$1" == "" ] ; then
  echo "Usage: $0 K3D_CLUSTER_NAME"
  exit 1
fi
CLUSTER_NAME=$1
# k3d prepends "k3d-" to the cluster name
K3D_CLUSTER_NAME="k3d-${CLUSTER_NAME}"

# ex: 172.24.0.0/16
CIDR_BLOCK=$(docker network inspect $K3D_CLUSTER_NAME | jq -r '.[0].IPAM.Config[0].Subnet')

# ex: 172.24.0.0
CIDR_BASE_ADDR=${CIDR_BLOCK%???}

# careful! this will only work for /16 networks, need to do maths otherwise...
# also reserve a chunk at the start of the range
INGRESS_FIRST_ADDR=$(echo $CIDR_BASE_ADDR | awk -F'.' '{print $1,$2,0,100}' OFS='.')
INGRESS_LAST_ADDR=$(echo $CIDR_BASE_ADDR | awk -F'.' '{print $1,$2,255,255}' OFS='.')
INGRESS_RANGE="${INGRESS_FIRST_ADDR}-${INGRESS_LAST_ADDR}"

echo "configuring metallb address pool: ${INGRESS_RANGE}"

cat <<EOF | kubectl apply -f -
apiVersion: metallb.io/v1beta1
kind: IPAddressPool
metadata:
  name: default
  namespace: metallb-system
spec:
  addresses:
  # Address pool MetalLB will allocate from, adjust your router to not
  # allocate address in this range to prevent clash
  - $INGRESS_RANGE
EOF

cat <<EOF | kubectl apply -f -
apiVersion: metallb.io/v1beta1
kind: L2Advertisement
metadata:
  name: default-advertisement
  namespace: metallb-system
EOF