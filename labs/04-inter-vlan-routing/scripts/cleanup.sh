#!/bin/bash

echo "[+] Cleaning Lab 04..."

ip netns del pc-a 2>/dev/null || true
ip netns del pc-b 2>/dev/null || true
ip netns del pc-c 2>/dev/null || true
ip netns del pc-d 2>/dev/null || true
ip netns del router 2>/dev/null || true

ip link del br0 2>/dev/null || true

echo "[+] Lab 04 cleanup complete."
