# Lab 03 — VLAN Segmentation

## Overview

This lab demonstrates Layer 2 network segmentation using VLANs on a Linux bridge.

Four isolated network namespaces were connected to a single VLAN-aware Linux bridge. Two hosts were assigned to VLAN 10 and two hosts to VLAN 20.

The lab verifies that:

- hosts within the same VLAN can communicate
- hosts in different VLANs remain isolated without Layer 3 routing
- ARP broadcasts remain inside their VLAN broadcast domain
- the Linux bridge learns MAC addresses independently for each VLAN

## Objectives

- Understand VLAN-based Layer 2 segmentation
- Configure VLAN-aware switch ports
- Understand access port behaviour
- Verify VLAN membership
- Test same-VLAN connectivity
- Demonstrate inter-VLAN isolation
- Observe ARP broadcast boundaries
- Inspect the bridge forwarding database

## Topology

```text
PC-A                           PC-C
VLAN 10                        VLAN 20
10.10.10.10/24                 10.10.20.10/24
   |                              |
   | access                       | access
   |                              |
   +--------- Linux Bridge -------+
                br0
   +------------------------------+
   |                              |
   | access                       | access
   |                              |
PC-B                           PC-D
VLAN 10                        VLAN 20
10.10.10.20/24                 10.10.20.20/24
