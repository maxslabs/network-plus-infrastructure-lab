#!/bin/bash

for ns in pc-a pc-b pc-c pc-d; do
    ip netns del "$ns" 2>/dev/null || true
done

ip link del br0 2>/dev/null || true

echo "Lab 03 VLAN topology removed."
