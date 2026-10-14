#!/bin/bash
# Explicitly owns these lab namespace/link names, including a manually built lab.
set -Eeuo pipefail
RUN=/run/networkplus-lab05
[[ $EUID == 0 ]] || { echo 'Run with sudo.' >&2; exit 1; }
for tool in ip flock; do command -v "$tool" >/dev/null; done
exec 9>/run/lock/networkplus-lab05.lock
flock -n 9 || { echo 'Another Lab 05 operation is running.' >&2; exit 1; }
has_ns() { ip netns list | awk '{print $1}' | grep -Fxq "$1"; }
if has_ns pc-a && [[ -s $RUN/dhclient.pid ]] && command -v dhclient >/dev/null; then
  timeout 5 ip netns exec pc-a dhclient -4 -r -pf "$RUN/dhclient.pid" \
    -lf "$RUN/client.leases" -sf "$RUN/dhclient-hook" veth-a || true
fi
# Enumerate namespace members rather than trusting possibly stale/reused PID files.
# This also stops DHCP clients/dnsmasq from the original manually constructed lab.
for ns in pc-a dhcp-server auth-dns; do
  has_ns "$ns" || continue
  mapfile -t pids < <(ip netns pids "$ns")
  for pid in "${pids[@]}"; do kill -TERM "$pid" 2>/dev/null || true; done
  for ((attempt=0; attempt<30; attempt++)); do
    [[ -z $(ip netns pids "$ns") ]] && break
    sleep 0.1
  done
  mapfile -t pids < <(ip netns pids "$ns")
  for pid in "${pids[@]}"; do kill -KILL "$pid" 2>/dev/null || true; done
  ip netns delete "$ns"
done
for dev in veth-a-br veth-dhcp-br veth-auth-br veth-a veth-dhcp veth-auth br0; do
  if ip link show "$dev" >/dev/null 2>&1; then ip link delete "$dev"; fi
done
rm -f "$RUN/managed" "$RUN/resolver.pid" "$RUN/authoritative.pid" "$RUN/dhclient.pid"
echo "Lab 05 removed. Saved evidence is untouched; runtime logs/leases remain in $RUN."
