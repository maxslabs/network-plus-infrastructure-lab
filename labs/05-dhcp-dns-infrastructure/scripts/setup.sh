#!/bin/bash
# Lab 05 only. Existing unmanaged topology is never replaced by setup.
set -Eeuo pipefail
LAB=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
RUN=/run/networkplus-lab05
[[ $EUID == 0 ]] || { echo 'Run with sudo.' >&2; exit 1; }
for tool in ip flock dhclient timeout unshare mount; do command -v "$tool" >/dev/null || { echo "Missing: $tool" >&2; exit 1; }; done
[[ -x /usr/sbin/dhclient && -f /usr/sbin/dhclient-script ]] || { echo 'Missing ISC dhclient or its standard script.' >&2; exit 1; }
[[ -x /usr/sbin/dnsmasq ]] || { echo 'Missing /usr/sbin/dnsmasq' >&2; exit 1; }
exec 9>/run/lock/networkplus-lab05.lock
flock -n 9 || { echo 'Another Lab 05 operation is running.' >&2; exit 1; }
for conf in resolver authoritative; do
  [[ -r $LAB/configs/dnsmasq-$conf.conf ]]
  /usr/sbin/dnsmasq --test --conf-file="$LAB/configs/dnsmasq-$conf.conf"
done
if [[ -f $RUN/managed ]]; then
  echo 'Lab runtime already exists. Use cleanup.sh before rebuilding (logs and leases remain).'
  exit 0
fi
for ns in pc-a dhcp-server auth-dns; do
  if ip netns list | awk '{print $1}' | grep -Fxq "$ns"; then
    echo "Existing namespace $ns: preserve evidence, then run cleanup.sh explicitly." >&2; exit 1
  fi
done
for dev in br0 veth-a veth-a-br veth-dhcp veth-dhcp-br veth-auth veth-auth-br; do
  if ip link show "$dev" >/dev/null 2>&1; then echo "Existing link $dev; refusing to replace it." >&2; exit 1; fi
done
install -d -m 0755 "$RUN"
touch "$RUN/managed"
rollback() {
  local status=$1 line=$2 command=$3
  trap - ERR
  printf 'Setup failed at line %s (exit %s): %s\n' "$line" "$status" "$command" >&2
  if [[ -f $RUN/dhclient.log ]]; then tail -n 25 "$RUN/dhclient.log" >&2; fi
  echo 'Removing partial lab; logs are retained.' >&2
  flock -u 9
  "$LAB/scripts/cleanup.sh" || echo 'Cleanup incomplete; inspect lab resources.' >&2
  exit "$status"
}
trap 'rollback "$?" "$LINENO" "$BASH_COMMAND"' ERR
ip link add br0 type bridge
ip link set br0 up
for spec in 'pc-a a' 'dhcp-server dhcp' 'auth-dns auth'; do
  read -r ns suffix <<< "$spec"
  ip netns add "$ns"
  ip link add "veth-$suffix" type veth peer name "veth-$suffix-br"
  ip link set "veth-$suffix" netns "$ns"
  ip link set "veth-$suffix-br" master br0
  ip link set "veth-$suffix-br" up
  ip -n "$ns" link set lo up
  if [[ $ns == pc-a ]]; then ip -n "$ns" link set veth-a address 82:1f:2b:04:8e:aa; fi
  ip -n "$ns" link set "veth-$suffix" up
done
ip -n dhcp-server addr add 10.50.50.1/24 dev veth-dhcp
ip -n auth-dns addr add 10.50.50.2/24 dev veth-auth
# Command-line runtime paths override defaults; captured configs stay untouched.
for spec in 'auth-dns authoritative' 'dhcp-server resolver'; do
  read -r ns role <<< "$spec"
  ip netns exec "$ns" /usr/sbin/dnsmasq \
    --conf-file="$LAB/configs/dnsmasq-$role.conf" \
    --pid-file="$RUN/$role.pid" --log-facility="$RUN/$role.log" \
    --dhcp-leasefile="$RUN/$role.leases" --log-queries --log-dhcp 9>&-
  [[ -s $RUN/$role.pid ]]
  kill -0 "$(cat "$RUN/$role.pid")"
done
# Custom hook configures this namespace only, never the host's resolver files.
cat > "$RUN/dhclient-hook" <<'HOOK'
#!/bin/bash
set -e
case "$reason" in
  BOUND|RENEW|REBIND|REBOOT)
    ip -4 addr flush dev "$interface"
    ip addr add "$new_ip_address/24" dev "$interface"
    ip route replace default via 10.50.50.1 dev "$interface"
    ;;
  EXPIRE|FAIL|RELEASE|STOP) ip -4 addr flush dev "$interface" ;;
esac
exit 0
HOOK
chmod 755 "$RUN/dhclient-hook"
# Debian's dhclient AppArmor profile permits these PID/lease names and the
# standard hook path. Bind our hook there only in a private mount namespace;
# the host's installed hook and resolver files are never modified.
timeout 45 ip netns exec pc-a unshare --mount --propagation private \
  bash -eu -c '
    mount --bind "$1" /usr/sbin/dhclient-script
    exec /usr/sbin/dhclient -4 -1 -v \
      -pf /run/dhclient-lab05.pid -lf /run/dhclient-lab05.leases \
      -sf /usr/sbin/dhclient-script veth-a
  ' lab05-dhcp "$RUN/dhclient-hook" >"$RUN/dhclient.log" 2>&1 9>&-
ip -n pc-a -4 addr show dev veth-a | grep -q 'inet 10.50.50.110/24'
trap - ERR
echo "Lab 05 ready. Runtime logs, PIDs and leases: $RUN"
ip -n pc-a -4 addr show dev veth-a
ip -n pc-a route
