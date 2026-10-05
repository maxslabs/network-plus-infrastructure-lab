#!/bin/bash
set -e

# Create namespaces
for ns in pc-a pc-b pc-c pc-d; do
    ip netns add "$ns"
done

# Create VLAN-aware Linux bridge
ip link add br0 type bridge vlan_filtering 1
ip link set br0 up

# Create veth pairs
ip link add veth-a type veth peer name veth-a-br
ip link add veth-b type veth peer name veth-b-br
ip link add veth-c type veth peer name veth-c-br
ip link add veth-d type veth peer name veth-d-br

# Move host-side interfaces into namespaces
ip link set veth-a netns pc-a
ip link set veth-b netns pc-b
ip link set veth-c netns pc-c
ip link set veth-d netns pc-d

# Connect switch-side interfaces to bridge
for iface in veth-a-br veth-b-br veth-c-br veth-d-br; do
    ip link set "$iface" master br0
    ip link set "$iface" up
done

# Bring namespace interfaces up
ip netns exec pc-a ip link set lo up
ip netns exec pc-a ip link set veth-a up

ip netns exec pc-b ip link set lo up
ip netns exec pc-b ip link set veth-b up

ip netns exec pc-c ip link set lo up
ip netns exec pc-c ip link set veth-c up

ip netns exec pc-d ip link set lo up
ip netns exec pc-d ip link set veth-d up

# Remove default VLAN 1 from access ports
for iface in veth-a-br veth-b-br veth-c-br veth-d-br; do
    /usr/sbin/bridge vlan del dev "$iface" vid 1
done

# Configure access VLANs
/usr/sbin/bridge vlan add dev veth-a-br vid 10 pvid untagged
/usr/sbin/bridge vlan add dev veth-b-br vid 10 pvid untagged
/usr/sbin/bridge vlan add dev veth-c-br vid 20 pvid untagged
/usr/sbin/bridge vlan add dev veth-d-br vid 20 pvid untagged

# Assign IP addresses
ip netns exec pc-a ip addr add 10.10.10.10/24 dev veth-a
ip netns exec pc-b ip addr add 10.10.10.20/24 dev veth-b
ip netns exec pc-c ip addr add 10.10.20.10/24 dev veth-c
ip netns exec pc-d ip addr add 10.10.20.20/24 dev veth-d

echo "Lab 03 VLAN topology created."
/usr/sbin/bridge vlan show
