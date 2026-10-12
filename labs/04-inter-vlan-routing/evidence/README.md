# Lab 04 Evidence

## Provenance

I completed this lab by building and testing inter-VLAN routing, correcting my setup script, and verifying a successful rebuild. My session record includes the final setup trace, the corrected link commands, and the successful PC-A to PC-C ping.

I documented my packet-capture observations, route and neighbour inspection, and deliberate forwarding failure in the session notes. The original terminal transcripts and PCAP files for those checks are not included here. I label expected configuration separately from recorded output and have not reconstructed MAC addresses, timestamps, ICMP identifiers, or capture output.

## Evidence Index

| Item | Source | Result / Location |
|---|---|---|
| PC-A to PC-C ping after rebuild | My recorded terminal output | [connectivity-test.txt](connectivity-test.txt): 2/2 replies, 0% loss, TTL 63 |
| Automated setup | My final shell trace and setup script | Creates all five namespaces, bridge, access VLANs, trunk, subinterfaces, addresses and default routes; enables forwarding |
| Cleanup and rebuild | My session notes, setup trace and ping | Rebuild validated in session; no separate cleanup transcript retained |
| PC-A routing and neighbour tables | My session notes | [routing-and-neighbours.md](routing-and-neighbours.md); expected routes separated from raw evidence |
| Router routing table | My session notes | Two connected networks; see routing notes |
| Trunk and access tcpdump | My session notes | [../captures/README.md](../captures/README.md); raw captures unavailable |
| Forwarding disabled then restored | My session notes | [../troubleshooting.md](../troubleshooting.md) |

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
