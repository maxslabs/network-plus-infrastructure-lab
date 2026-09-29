#!/bin/bash
set -e

echo "[+] Cleaning previous lab state..."

ip netns del workstation 2>/dev/null || true
ip netns del router-a 2>/dev/null || true
ip netns del router-b 2>/dev/null || true
ip netns del router-c 2>/dev/null || true

echo "[+] Creating network namespaces..."

ip netns add workstation
ip netns add router-a
ip netns add router-b
ip netns add router-c

echo "[+] Creating virtual Ethernet links..."

# Workstation <-> Router A
ip link add veth-ws type veth peer name veth-ra1

# Router A <-> Router B
ip link add veth-ra2 type veth peer name veth-rb1

# Router B <-> Router C
ip link add veth-rb2 type veth peer name veth-rc1

# Router C <-> Router A
ip link add veth-rc2 type veth peer name veth-ra3

echo "[+] Assigning interfaces to namespaces..."

ip link set veth-ws netns workstation

ip link set veth-ra1 netns router-a
ip link set veth-ra2 netns router-a
ip link set veth-ra3 netns router-a

ip link set veth-rb1 netns router-b
ip link set veth-rb2 netns router-b

ip link set veth-rc1 netns router-c
ip link set veth-rc2 netns router-c

echo "[+] Configuring IP addresses..."

# Workstation
ip netns exec workstation ip addr add 10.10.10.10/24 dev veth-ws

# Router A
ip netns exec router-a ip addr add 10.10.10.1/24 dev veth-ra1
ip netns exec router-a ip addr add 10.10.20.1/24 dev veth-ra2
ip netns exec router-a ip addr add 10.10.40.2/24 dev veth-ra3

# Router B
ip netns exec router-b ip addr add 10.10.20.2/24 dev veth-rb1
ip netns exec router-b ip addr add 10.10.30.1/24 dev veth-rb2

# Router C
ip netns exec router-c ip addr add 10.10.30.2/24 dev veth-rc1
ip netns exec router-c ip addr add 10.10.40.1/24 dev veth-rc2

echo "[+] Bringing interfaces online..."

ip netns exec workstation ip link set lo up
ip netns exec workstation ip link set veth-ws up

ip netns exec router-a ip link set lo up
ip netns exec router-a ip link set veth-ra1 up
ip netns exec router-a ip link set veth-ra2 up
ip netns exec router-a ip link set veth-ra3 up

ip netns exec router-b ip link set lo up
ip netns exec router-b ip link set veth-rb1 up
ip netns exec router-b ip link set veth-rb2 up

ip netns exec router-c ip link set lo up
ip netns exec router-c ip link set veth-rc1 up
ip netns exec router-c ip link set veth-rc2 up

echo "[+] Enabling IPv4 forwarding..."

ip netns exec router-a sysctl -w net.ipv4.ip_forward=1 >/dev/null
ip netns exec router-b sysctl -w net.ipv4.ip_forward=1 >/dev/null
ip netns exec router-c sysctl -w net.ipv4.ip_forward=1 >/dev/null

echo "[+] Configuring workstation gateway..."

ip netns exec workstation ip route add default via 10.10.10.1

echo "[+] Configuring deliberate routing loop..."

# Router A -> Router B
ip netns exec router-a ip route add 172.16.50.0/24 via 10.10.20.2

# Router B -> Router C
ip netns exec router-b ip route add 172.16.50.0/24 via 10.10.30.2

# Router C -> Router A
ip netns exec router-c ip route add 172.16.50.0/24 via 10.10.40.2

echo "[+] Configuring source-network return routes..."

# Required for source reachability and Linux loose reverse-path filtering.
ip netns exec router-b ip route add 10.10.10.0/24 via 10.10.20.1
ip netns exec router-c ip route add 10.10.10.0/24 via 10.10.40.2

echo
echo "[+] Routing loop lab deployed successfully."
echo
echo "Workstation: 10.10.10.10/24"
echo "Router A:    10.10.10.1 | 10.10.20.1 | 10.10.40.2"
echo "Router B:    10.10.20.2 | 10.10.30.1"
echo "Router C:    10.10.30.2 | 10.10.40.1"
echo
echo "Loop target: 172.16.50.0/24"
echo "Loop path:   Router A -> Router B -> Router C -> Router A"
echo
echo "Test with:"
echo "ip netns exec workstation ping -c 1 -t 5 172.16.50.10"
