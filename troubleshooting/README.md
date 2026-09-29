# Network Troubleshooting Log

This directory maintains a record of network faults encountered or intentionally introduced throughout the Network+ Infrastructure Lab.

The purpose is to document the troubleshooting process rather than only the final solution.

Each entry records the observed symptom, investigation, root cause and resolution.

## Troubleshooting Cases

### 001 - Remote Network Unreachable

**Lab:** [Linux Multi-Subnet Routing](../labs/01-linux-multi-subnet-routing/)

**Symptom**

The workstation could communicate with devices on its local `10.10.10.0/24` network but could not reach the server at `10.10.20.10`.

The system reported:

```text
Network is unreachable
```

**Investigation**

The workstation routing table was inspected and contained only the directly connected `10.10.10.0/24` network.

There was no route instructing the workstation where to send traffic destined for remote networks.

**Root Cause**

No default gateway had been configured.

**Resolution**

A default route was added through the router interface:

```bash
ip route add default via 10.10.10.1
```

---

### 002 - Router Not Forwarding Traffic

**Lab:** [Linux Multi-Subnet Routing](../labs/01-linux-multi-subnet-routing/)

**Symptom**

After configuring the workstation default gateway, traffic could reach the router but communication with the remote server still failed.

**Investigation**

The router had directly connected routes for both:

```text
10.10.10.0/24
10.10.20.0/24
```

Its IPv4 forwarding state was then inspected:

```bash
sysctl net.ipv4.ip_forward
```

The result showed:

```text
net.ipv4.ip_forward = 0
```

**Root Cause**

The Linux system knew routes to both networks but IPv4 packet forwarding was disabled.

**Resolution**

IPv4 forwarding was enabled:

```bash
sysctl -w net.ipv4.ip_forward=1
```

---

### 003 - Missing Return Path

**Lab:** [Linux Multi-Subnet Routing](../labs/01-linux-multi-subnet-routing/)

**Symptom**

Routing configuration existed on the workstation and router, but successful end-to-end communication required the destination server to return traffic toward the source network.

**Investigation**

The server routing table contained its directly connected `10.10.20.0/24` network but initially had no route toward the workstation's `10.10.10.0/24` network.

**Root Cause**

The server had no gateway for destinations outside its local subnet.

**Resolution**

A default route was configured through the server-side router interface:

```bash
ip route add default via 10.10.20.1
```

With routing configured in both directions and IPv4 forwarding enabled, ICMP communication between `10.10.10.10` and `10.10.20.10` succeeded.

### 004 - Incorrect Prefix Length Prevented Direct Routing

**Lab:** [Routing Loops and TTL](../labs/02-routing-loops-and-ttl/)

**Symptom**

Router B could not reach Router C across the `10.10.30.0/24` transit network. Attempts to use Router C as the next hop resulted in:

```text
Network is unreachable
```

**Investigation**

The interfaces connecting Router B and Router C were inspected and had accidentally been configured with `/32` prefixes:

```text
Router B: 10.10.30.1/32
Router C: 10.10.30.2/32
```

This prevented Linux from installing the intended directly connected route for the shared `10.10.30.0/24` transit network.

**Root Cause**

The Router B to Router C interfaces were configured with an incorrect `/32` prefix length instead of `/24`.

**Resolution**

The addresses were corrected to:

```text
Router B: 10.10.30.1/24
Router C: 10.10.30.2/24
```

Linux then installed the connected route for `10.10.30.0/24`, allowing direct communication between the routers.

---

### 005 - Reverse-Path Filtering Prevented Forwarding

**Lab:** [Routing Loops and TTL](../labs/02-routing-loops-and-ttl/)

**Symptom**

Router B received an ICMP packet from the workstation but did not forward it toward Router C, despite IPv4 forwarding being enabled and a valid destination route being present.

**Investigation**

Packet captures confirmed that the packet reached Router B. IPv4 forwarding was enabled, the destination route existed, and the next hop was reachable.

Reverse-path filtering was then inspected:

```bash
sysctl net.ipv4.conf.veth-rb1.rp_filter
```

The interface returned:

```text
net.ipv4.conf.veth-rb1.rp_filter = 2
```

The packet originated from `10.10.10.10`, but Router B initially had no route to the source network `10.10.10.0/24`. Router C required equivalent source-network reachability.

**Root Cause**

Linux loose reverse-path filtering rejected the traffic because the routers lacked appropriate routing information toward the packet's source network.

**Resolution**

A source-network route was added to Router B:

```bash
ip route add 10.10.10.0/24 via 10.10.20.1
```

Router C was configured with:

```bash
ip route add 10.10.10.0/24 via 10.10.40.2
```

After source-network reachability was established, packet captures confirmed successful forwarding through the complete routing loop.

This demonstrated that Linux forwarding troubleshooting can require checking source reachability and reverse-path validation in addition to destination routes and `ip_forward`.

---

## Troubleshooting Method

The general troubleshooting process used throughout this project is:

```text
Identify symptom
      ↓
Determine affected network layer
      ↓
Inspect local interface configuration
      ↓
Inspect addressing and subnet boundaries
      ↓
Inspect routing / next-hop information
      ↓
Verify forwarding and filtering behaviour
      ↓
Capture traffic where necessary
      ↓
Identify root cause
      ↓
Apply fix
      ↓
Retest and document
```

Future labs will expand this log with Layer 2, routing, DHCP, DNS, VLAN, NAT, firewall, IPv6 and other network troubleshooting scenarios.
