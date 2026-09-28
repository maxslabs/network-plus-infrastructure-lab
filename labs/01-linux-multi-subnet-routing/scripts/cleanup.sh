#!/bin/bash

set -e

echo "[+] Removing network namespaces..."

ip netns del workstation 2>/dev/null || true
ip netns del router 2>/dev/null || true
ip netns del server01 2>/dev/null || true

echo "[+] Lab environment removed."
