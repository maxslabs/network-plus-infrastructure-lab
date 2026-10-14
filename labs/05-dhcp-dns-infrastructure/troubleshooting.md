# Lab 05 troubleshooting and controlled break/fix

Run commands from this lab directory. Use explicit DNS server addresses; namespace network isolation does not by itself isolate `/etc/resolv.conf`.

| Symptom | Inspect | Likely cause / repair |
|---|---|---|
| Setup refuses existing objects | `sudo ip netns list`; `ip -br link` | Original manual lab still exists. Preserve evidence, then explicitly run cleanup and setup. |
| No DHCP address | `/run/networkplus-lab05/dhclient.log`, `resolver.log`; namespace interface and bridge ports | Link down, wrong DHCP interface, missing server or DHCP client. Repair link/config, rebuild. |
| Address is not .110 | `sudo ip -n pc-a link show veth-a`; reservation config; runtime resolver leases | Client MAC must be 82:1f:2b:04:8e:aa. Setup fixes MAC before acquisition. |
| server01 A/PTR fails | Query .1 directly; resolver log and config | Wrong record, listener/interface or stopped resolver. |
| cachetest fails but server01 works | Query .2 directly; authoritative log; conditional server directive | Upstream link/service or forwarding target broken. |
| TTL starts below 120 | Repeated query/logs | Cache is already warm; rebuild and query again. |
| External names/Internet fail | Routes and upstream reachability | Lab provides no Internet router/NAT. This is outside this topology. |

## Link failure

```bash
sudo ip -n auth-dns link set veth-auth down
sudo ip netns exec pc-a dig +time=2 +tries=1 @10.50.50.1 cachetest.maxslabs.test
sudo ip -n auth-dns link set veth-auth up
```

A warm resolver cache can still answer while upstream is down. For a deliberate miss, wait until the observed TTL expires before querying. After repair, compare direct upstream and resolver answers:

```bash
sudo ip netns exec pc-a dig @10.50.50.2 cachetest.maxslabs.test
sudo ip netns exec pc-a dig @10.50.50.1 cachetest.maxslabs.test
```

Expected: both return 10.50.50.99; resolver TTL may decrease on repeated queries.

## Reservation / DORA investigation

Inspect the client MAC and runtime leases:

```bash
sudo ip -n pc-a link show veth-a
sudo cat /run/networkplus-lab05/resolver.leases
sudo cat /run/networkplus-lab05/dhclient.log
```

For a deliberate reservation break, back up the resolver config separately, change its reservation MAC to a different valid locally administered MAC, and rebuild with cleanup/setup. Compare the assigned address and lease entry. Restore the original config and rebuild; expect .110 again. Do not change the captured evidence or infer DORA packets solely from a lease file.

## Conditional forwarding break

Back up the resolver config, change its maxslabs.test forwarding target from .2 to an unused address, then cleanup/setup. The locally supplied server01 A/PTR should still answer; cachetest should time out or fail. Restore .2 and rebuild, then verify both lookups. Record actual results rather than assuming a particular DNS failure code.

## Process and port checks

```bash
sudo ip netns exec dhcp-server ss -lunp
sudo ip netns exec auth-dns ss -lunp
sudo tail -n 40 /run/networkplus-lab05/resolver.log
sudo tail -n 40 /run/networkplus-lab05/authoritative.log
```

DNS listens on port 53 (UDP/TCP); DHCP server uses UDP 67. Cleanup enumerates processes inside each lab namespace, avoiding stale PID-file kills against unrelated host processes. Runtime logs and leases survive cleanup but not reboot. Cleanup also deletes br0 and named veth peers, so these names must belong exclusively to this lab.

## DHCP ACK received, but client address missing

The first scripted run completed Discover, Offer, Request and ACK for 10.50.50.110, but dhclient reported `Permission denied` for its custom hook and lease file under `/run/networkplus-lab05`. The address could not be applied, so setup rolled back.

The installed AppArmor profile permits `/run/dhclient*.pid`, `/run/dhclient*.lease*`, and execution of the standard dhclient script. Setup now uses those permitted client filenames and mounts the lab hook over `/usr/sbin/dhclient-script` in a private mount namespace. The host script and AppArmor policy remain unchanged. The client retains this mount namespace for renewals; cleanup uses the same arrangement for release. Setup failures now print the failing command and the client log before rollback.
