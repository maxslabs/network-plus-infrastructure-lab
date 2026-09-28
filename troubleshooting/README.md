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
