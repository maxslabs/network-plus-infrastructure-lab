#!/bin/bash
# Explicitly owns these lab namespace/link names, including a manually built lab.
set -Eeuo pipefail
RUN=/run/networkplus-lab05
[[ $EUID == 0 ]] || { echo 'Run with sudo.' >&2; exit 1; }
for tool in ip flock; do command -v "$tool" >/dev/null; done
exec 9>/run/lock/networkplus-lab05.lock
flock -n 9 || { echo 'Another Lab 05 operation is running.' >&2; exit 1; }
has_ns() { ip netns list | awk '{print $1}' | grep -Fxq "$1"; }
# Release only if this PID still belongs to the lab namespace. Never signal
# an unrelated process through a stale dhclient PID file.
if has_ns pc-a && [[ -s /run/dhclient-lab05.pid && -f $RUN/dhclient-hook ]]; then
  client_pid=$(cat /run/dhclient-lab05.pid)
  if [[ $client_pid =~ ^[0-9]+$ ]] && ip netns pids pc-a | grep -Fxq "$client_pid"; then
    timeout 5 ip netns exec pc-a unshare --mount --propagation private \
      bash -eu -c '
        mount --bind "$1" /usr/sbin/dhclient-script
    # /run is noexec on this host; enable only this private bind mount.
    mount -o remount,bind,exec /usr/sbin/dhclient-script
        exec /usr/sbin/dhclient -4 -r -pf /run/dhclient-lab05.pid \
          -lf /run/dhclient-lab05.leases -sf /usr/sbin/dhclient-script veth-a
      ' lab05-release "$RUN/dhclient-hook" 9>&- || true
  fi
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
  if ip link show "$dev" >/dev/null 2>&1; then
    # Namespace destruction may asynchronously remove the peer after the check.
    if ! ip link delete "$dev" 2>/dev/null; then
      if ip link show "$dev" >/dev/null 2>&1; then
        echo "Could not remove lab link: $dev" >&2
        exit 1
      fi
    fi
  fi
done
rm -f "$RUN/managed" "$RUN/resolver.pid" "$RUN/authoritative.pid" "$RUN/dhclient.pid" /run/dhclient-lab05.pid
echo "Lab 05 removed. Saved evidence is untouched; runtime logs/leases remain in $RUN."
