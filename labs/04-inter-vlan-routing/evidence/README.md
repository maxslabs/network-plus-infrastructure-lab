# Lab 04 Evidence

## Provenance

This portfolio records Max's completed “Start Lab 04” session and the verified topology supplied with the handoff. The available conversation contains the final setup trace, corrected link commands, and the successful PC-A to PC-C ping. The existing local scripts were also inspected.

The packet-capture observations, route/neighbor inspection, and deliberate forwarding failure are supplied session observations. Their original terminal transcripts and PCAP files were not available in the local Lab 04 directory or retrieved chat. Notes distinguish these observations from expected configuration; no MAC addresses, timestamps, ICMP identifiers, or capture output have been invented.

## Evidence Index

| Item | Source | Result / Location |
|---|---|---|
| PC-A to PC-C ping after rebuild | Recorded user terminal output | [connectivity-test.txt](connectivity-test.txt): 2/2 replies, 0% loss, TTL 63 |
| Automated setup | Recorded final shell trace and retained script | Creates all five namespaces, bridge, access VLANs, trunk, subinterfaces, addresses and default routes; enables forwarding |
| Cleanup and rebuild | Completed-session handoff, followed by setup trace and ping | Rebuild validated in session; no separate cleanup transcript retained |
| PC-A routing and neighbour tables | Supplied session observation | [routing-and-neighbours.md](routing-and-neighbours.md); expected routes separated from raw evidence |
| Router routing table | Supplied session observation | Two connected networks; see routing notes |
| Trunk and access tcpdump | Supplied session observation | [../captures/README.md](../captures/README.md); raw captures unavailable |
| Forwarding disabled then restored | Supplied session observation | [../troubleshooting.md](../troubleshooting.md) |

## Collecting Fresh State

Run these commands from the Lab 04 directory after setup. They create fresh evidence from the current run; they do not reproduce the historical transcript.

```bash
sudo bridge vlan show > evidence/bridge-vlan-membership.txt
sudo ip -d link show br0 > evidence/bridge-state.txt
sudo ip netns exec pc-a ip route show > evidence/pc-a-routing-table.txt
sudo ip netns exec pc-a ping -c 2 10.10.20.10 > evidence/fresh-connectivity-test.txt
sudo ip netns exec pc-a ip neigh show > evidence/pc-a-neighbour-table.txt
sudo ip netns exec router ip route show > evidence/router-routing-table.txt
sudo ip netns exec router sysctl net.ipv4.ip_forward > evidence/router-forwarding.txt
```

Record the run date and capture commands alongside any new files. Inspect neighbour entries after traffic has resolved the next hop; MAC addresses and neighbour states vary by run.
