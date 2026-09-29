#!/bin/bash

echo "[+] Removing network namespaces..."

ip netns del workstation 2>/dev/null || true
ip netns del router-a 2>/dev/null || true
ip netns del router-b 2>/dev/null || true
ip netns del router-c 2>/dev/null || true

echo "[+] Lab environment removed."
