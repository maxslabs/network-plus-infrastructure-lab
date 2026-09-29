# Network+ Infrastructure Lab

A progressive networking homelab built to develop practical infrastructure, packet-analysis, and troubleshooting skills alongside CompTIA Network+ objectives.

Rather than documenting networking theory alone, each lab implements concepts in a working environment, captures and analyses network traffic, introduces or investigates failure conditions, and documents the troubleshooting process used to identify and resolve them.

## Lab Environment

The project primarily uses Linux-based virtual networking to create reproducible network topologies without requiring dedicated networking hardware.

Technologies and tools used throughout the project include:

- Linux network namespaces
- Virtual Ethernet (`veth`) interfaces
- IPv4 and IPv6
- Linux routing
- Bash
- `iproute2`
- `tcpdump`
- Wireshark
- Graphviz
- Network diagnostic utilities

Additional systems and networking technologies will be introduced as the lab develops.

## Labs

| Lab | Topic | Status |
|---|---|---|
| [01 - Linux Multi-Subnet Routing](labs/01-linux-multi-subnet-routing/) | Subnetting, routing, default gateways, IPv4 forwarding, ARP and ICMP packet analysis | Complete |
| [02 - Routing Loops and TTL](labs/02-routing-loops-and-ttl/) | Static routing loops, IPv4 TTL, ICMP Time Exceeded, reverse-path filtering and packet analysis | Complete |
| 03 - VLAN Segmentation | VLANs and Layer 2 network segmentation | Planned |
| 04 - Inter-VLAN Routing | Routing between segmented VLAN networks | Planned |
| 05 - DHCP Network Services | Dynamic IPv4 configuration and DHCP behaviour | Planned |
| 06 - NAT and PAT | Address translation and port address translation | Planned |
| 07 - Firewall and ACL Segmentation | Traffic filtering and network access control | Planned |
| 08 - IPv6 Networking | IPv6 addressing, neighbour discovery and routing | Planned |

## Current Labs

### Lab 01 — Linux Multi-Subnet Routing

The first lab implements two IPv4 subnets connected through a Linux router:

```text
10.10.10.0/24                              10.10.20.0/24

+-------------+       +-------------+       +-------------+
| Workstation |       |    Router   |       |   Server01  |
|             |       |             |       |             |
| 10.10.10.10 |-------| 10.10.10.1 |       | 10.10.20.10 |
|             |       | 10.10.20.1 |-------|             |
+-------------+       +-------------+       +-------------+
```

This lab demonstrates subnetting, directly connected routes, default gateways, IPv4 forwarding, ARP resolution and ICMP packet flow.

### Lab 02 — Routing Loops and TTL

The second lab expands the environment into a three-router topology containing a deliberately configured routing loop:

```text
                    Workstation
                   10.10.10.10
                        |
                     Router A
                    /        \
                   /          \
             Router B ------ Router C
```

Traffic destined for `172.16.50.0/24` is deliberately routed in a loop:

```text
Router A -> Router B -> Router C -> Router A -> ...
```

Packet captures demonstrate IPv4 TTL decreasing as the packet is forwarded around the loop until it expires. The router where TTL reaches zero generates an ICMP Time Exceeded response, preventing the packet from circulating indefinitely.

The lab also documents troubleshooting involving an incorrect CIDR prefix and Linux reverse-path filtering (`rp_filter`).

Both labs are reproducible using the Bash setup and cleanup scripts included in their respective directories.

## Approach

Each lab is designed around four stages:

1. **Build** — Configure the network or service being studied.
2. **Verify** — Confirm expected behaviour using appropriate diagnostic tools.
3. **Analyse** — Inspect routing information, protocol behaviour and packet captures.
4. **Troubleshoot** — Diagnose configuration errors and network failures rather than only documenting successful configurations.

Where appropriate, lab evidence is retained in the repository, including routing tables, interface configuration, connectivity tests, packet captures and topology diagrams.

## Troubleshooting

Failures encountered during the labs are documented separately in the [troubleshooting log](troubleshooting/).

This provides a record of symptoms, investigation steps, root causes and resolutions instead of presenting only the final working configuration.

## Repository Structure

```text
network-plus-infrastructure-lab/
├── labs/
│   ├── 01-linux-multi-subnet-routing/
│   │   ├── captures/
│   │   ├── diagrams/
│   │   ├── evidence/
│   │   ├── scripts/
│   │   └── README.md
│   └── 02-routing-loops-and-ttl/
│       ├── captures/
│       ├── diagrams/
│       ├── evidence/
│       ├── scripts/
│       └── README.md
├── troubleshooting/
│   └── README.md
└── README.md
```

## Purpose

This repository documents my practical networking development while preparing for CompTIA Network+ and building a broader foundation for IT infrastructure and cybersecurity.

The focus is on understanding how networks behave in practice: building them, observing traffic, diagnosing failures and explaining why a solution works.
