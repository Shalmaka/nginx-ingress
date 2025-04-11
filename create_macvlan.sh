#!/bin/bash

# Source the .env file to read the variables
source .env

# Construct parent interface with VLAN ID
PARENT_IFACE="${INTERFACE_NAME}.${VLAN_ID}"

# Create the macvlan network using the MACVLAN_NAME from the .env file
docker network create -d macvlan \
  --subnet=${SUBNET} \
  --gateway=${GATEWAY} \
  -o parent=${PARENT_IFACE} \
  ${MACVLAN_NAME}

echo "macvlan network '${MACVLAN_NAME}' created successfully with parent interface '${PARENT_IFACE}'"
