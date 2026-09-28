#!/bin/bash

set -e

echo "[+] Creating network namespaces..."

ip netns add workstation
ip netns add router
ip netns add server01

echo "[+] Creating virtual Ethernet links..."

# Workstation <-> Router
ip link add veth-ws type veth peer name veth-r1
ip link set veth-ws netns workstation
ip link set veth-r1 netns router

# Router <-> Server
ip link add veth-r3 type veth peer name veth-srv
ip link set veth-r3 netns router
ip link set veth-srv netns server01

echo "[+] Configuring interfaces..."

# Workstation
ip netns exec workstation ip addr add 10.10.10.10/24 dev veth-ws
ip netns exec workstation ip link set veth-ws up
ip netns exec workstation ip link set lo up

# Router - Workstation subnet
ip netns exec router ip addr add 10.10.10.1/24 dev veth-r1
ip netns exec router ip link set veth-r1 up

# Router - Server subnet
ip netns exec router ip addr add 10.10.20.1/24 dev veth-r3
ip netns exec router ip link set veth-r3 up
ip netns exec router ip link set lo up

# Server01
ip netns exec server01 ip addr add 10.10.20.10/24 dev veth-srv
ip netns exec server01 ip link set veth-srv up
ip netns exec server01 ip link set lo up

echo "[+] Configuring routes..."

# Configure default gateway for workstation subnet
ip netns exec workstation ip route add default via 10.10.10.1

# Configure default gateway for server subnet
ip netns exec server01 ip route add default via 10.10.20.1

echo "[+] Enabling IPv4 forwarding..."

# Enable Layer 3 packet forwarding between router interfaces
ip netns exec router sysctl -w net.ipv4.ip_forward=1 >/dev/null

echo "[+] Lab deployment complete."
echo
echo "Workstation: 10.10.10.10/24"
echo "Router:      10.10.10.1/24 | 10.10.20.1/24"
echo "Server01:    10.10.20.10/24"
