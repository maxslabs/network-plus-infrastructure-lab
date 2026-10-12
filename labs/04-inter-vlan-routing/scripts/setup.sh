#!/bin/bash


set -e

echo "[+] Creating namespaces..."

ip netns add pc-a
ip netns add pc-b
ip netns add pc-c
ip netns add pc-d
ip netns add router

echo "[+] Creating VLAN-aware bridge..."

ip link add br0 type bridge
ip link set br0 type bridge vlan_filtering 1
ip link set br0 up

echo "[+] Creating PC-A connection..."

ip link add veth-a type veth peer name veth-a-br
ip link set veth-a netns pc-a
ip link set veth-a-br master br0
ip link set veth-a-br up
ip netns exec pc-a ip link set veth-a up
ip netns exec pc-a ip link set lo up

echo "[+] Creating PC-B connection..."

ip link add veth-b type veth peer name veth-b-br
ip link set veth-b netns pc-b
ip link set veth-b-br master br0
ip link set veth-b-br up
ip netns exec pc-b ip link set veth-b up
ip netns exec pc-b ip link set lo up

echo "[+] Creating PC-C connection..."

ip link add veth-c type veth peer name veth-c-br
ip link set veth-c netns pc-c
ip link set veth-c-br master br0
ip link set veth-c-br up
ip netns exec pc-c ip link set veth-c up
ip netns exec pc-c ip link set lo up

echo "[+] Creating PC-D connection..."

ip link add veth-d type veth peer name veth-d-br
ip link set veth-d netns pc-d
ip link set veth-d-br master br0
ip link set veth-d-br up
ip netns exec pc-d ip link set veth-d up
ip netns exec pc-d ip link set lo up

echo "[+] Configuring access VLANs..."

/usr/sbin/bridge vlan add dev veth-a-br vid 10 pvid untagged
/usr/sbin/bridge vlan add dev veth-b-br vid 10 pvid untagged
/usr/sbin/bridge vlan add dev veth-c-br vid 20 pvid untagged
/usr/sbin/bridge vlan add dev veth-d-br vid 20 pvid untagged

/usr/sbin/bridge vlan del dev veth-a-br vid 1
/usr/sbin/bridge vlan del dev veth-b-br vid 1
/usr/sbin/bridge vlan del dev veth-c-br vid 1
/usr/sbin/bridge vlan del dev veth-d-br vid 1

echo "[+] Creating router trunk..."

ip link add veth-rtr type veth peer name veth-rtr-br
ip link set veth-rtr netns router
ip link set veth-rtr-br master br0
ip link set veth-rtr-br up

ip netns exec router ip link set lo up
ip netns exec router ip link set veth-rtr up

/usr/sbin/bridge vlan add dev veth-rtr-br vid 10
/usr/sbin/bridge vlan add dev veth-rtr-br vid 20
/usr/sbin/bridge vlan del dev veth-rtr-br vid 1


echo "[+] Creating router VLAN subinterfaces..."

ip netns exec router ip link add link veth-rtr name veth-rtr.10 type vlan id 10
ip netns exec router ip link add link veth-rtr name veth-rtr.20 type vlan id 20

ip netns exec router ip link set veth-rtr.10 up
ip netns exec router ip link set veth-rtr.20 up

echo "[+] Assigning router IP addresses..."

ip netns exec router ip addr add 10.10.10.1/24 dev veth-rtr.10
ip netns exec router ip addr add 10.10.20.1/24 dev veth-rtr.20

echo "[+] Assigning host IP addresses..."

ip netns exec pc-a ip addr add 10.10.10.10/24 dev veth-a
ip netns exec pc-b ip addr add 10.10.10.20/24 dev veth-b
ip netns exec pc-c ip addr add 10.10.20.10/24 dev veth-c
ip netns exec pc-d ip addr add 10.10.20.20/24 dev veth-d

echo "[+] Adding default gateways..."

ip netns exec pc-a ip route add default via 10.10.10.1
ip netns exec pc-b ip route add default via 10.10.10.1
ip netns exec pc-c ip route add default via 10.10.20.1
ip netns exec pc-d ip route add default via 10.10.20.1

echo "[+] Enabling IPv4 forwarding..."

ip netns exec router sysctl -w net.ipv4.ip_forward=1 >/dev/null

echo
echo "[+] Lab 04 setup complete."
echo "    VLAN 10: PC-A 10.10.10.10, PC-B 10.10.10.20, GW 10.10.10.1"
echo "    VLAN 20: PC-C 10.10.20.10, PC-D 10.10.20.20, GW 10.10.20.1"
