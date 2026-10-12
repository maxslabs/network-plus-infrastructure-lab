# Lab 04 Packet Analysis

## Session Observations

During the lab, I observed:

- On `veth-rtr-br`, the same ICMP packet entered the router tagged VLAN 10 and left after routing tagged VLAN 20.
- On `veth-c-br`, IPv4 frames on PC-C's access link were untagged.

These are my session notes. The original PCAP files and tcpdump transcripts are not included here. I use the commands below to collect fresh evidence after rebuilding the lab.

## Capture Points

| Interface | Location | Expected Frame Format |
|---|---|---|
| `veth-rtr-br` | Host-side bridge trunk to router | 802.1Q VLAN 10 or VLAN 20 |
| `veth-c-br` | Host-side access port to PC-C | Untagged Ethernet carrying IPv4 |

## Text Capture

From the Lab 04 directory, use two terminals:

```bash
sudo tcpdump -i veth-rtr-br -nn -e -vvv -l > captures/trunk-icmp.txt 2> captures/trunk-icmp-status.txt
```

```bash
sudo tcpdump -i veth-c-br -nn -e -vvv -l > captures/access-pc-c-icmp.txt 2> captures/access-pc-c-icmp-status.txt
```

In another terminal:

```bash
sudo ip netns exec pc-a ping -c 2 10.10.20.10
```

Stop both captures with Ctrl-C once replies complete. The commands capture without a filter so VLAN tags do not cause an ordinary `icmp` filter to miss trunk packets. `-e` includes Ethernet headers and `-vvv` provides TTL and additional IP fields.

## Binary Capture

Alternatively, collect PCAP files with the same traffic generator. Run each capture in its own terminal and stop it after the ping:

```bash
sudo tcpdump -i veth-rtr-br -nn -s 0 -U -w captures/trunk-icmp.pcap
sudo tcpdump -i veth-c-br -nn -s 0 -U -w captures/access-pc-c-icmp.pcap
```

Read them using Wireshark or:

```bash
tcpdump -nn -e -vvv -r captures/trunk-icmp.pcap
tcpdump -nn -e -vvv -r captures/access-pc-c-icmp.pcap
```

## Comparing the Routed Packet

Match an echo request using source `10.10.10.10`, destination `10.10.20.10`, ICMP identifier, sequence number and payload, rather than timestamp alone. Compare VLAN 10 on ingress with VLAN 20 on egress at the trunk. IPv4 addresses remain the same, TTL decreases by one, and Ethernet next-hop addressing changes as the router builds the outgoing frame.

At `veth-c-br`, verify the request has EtherType IPv4 and no 802.1Q header. The VLAN 20 tag has been removed for the access link. Replies follow the reverse VLAN order across the trunk.

Keep run-specific identifiers, timestamps and MAC addresses from actual captures. Do not treat expected examples as historical evidence.
