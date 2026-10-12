# Lab 04 Troubleshooting Notes

## IPv4 Forwarding Disabled

**Symptom:** I deliberately set forwarding to `0` in the router namespace and observed inter-VLAN traffic fail.

**Investigation:** Check the router's connected routes, then inspect its forwarding state:

```bash
sudo ip netns exec router ip route show
sudo ip netns exec router sysctl net.ipv4.ip_forward
```

**Root cause:** Routes describe where packets can go, but the Linux router must also be permitted to forward them between interfaces.

**Resolution:** Restore forwarding inside the router namespace and retest:

```bash
sudo ip netns exec router sysctl -w net.ipv4.ip_forward=1
sudo ip netns exec pc-a ping -c 2 10.10.20.10
```

I observed failure at `0` and recovery at `1`. The original failure transcript is not included here. To repeat the deliberate fault on this lab, set `net.ipv4.ip_forward=0` with the same namespace-scoped command, test, then restore it to `1` before continuing.

## Missing veth Type in Setup

**Symptom:** The shell trace stopped while creating PC-C, then PC-D, with:

```text
Garbage instead of arguments "name ...". Try "ip link help".
```

**Investigation:** `sudo bash -x ./scripts/setup.sh` identified commands using `type peer` instead of `type veth peer`.

**Root cause:** The interface type argument `veth` was missing.

**Resolution:** I corrected both lines:

```bash
ip link add veth-c type veth peer name veth-c-br
ip link add veth-d type veth peer name veth-d-br
```

I cleaned the partial topology before rerunning setup. The final trace reached “Lab 04 setup complete”, and my subsequent PC-A to PC-C ping returned two replies with no loss. My scripts include these corrections.

## VLAN Filtering and Membership Checks

I also worked through VLAN-filtering and script issues during the session. The original error transcripts for those checks are not included here, so I have documented the verified final configuration below without assigning an unrecorded root cause.

```bash
sudo ip -d link show br0
sudo bridge vlan show
sudo ip netns exec router ip -d link show veth-rtr.10
sudo ip netns exec router ip -d link show veth-rtr.20
```

Verify `vlan_filtering 1`; VLAN 10 with PVID and Egress Untagged on `veth-a-br`/`veth-b-br`; VLAN 20 with those flags on `veth-c-br`/`veth-d-br`; and VLANs 10/20 without untagged flags on `veth-rtr-br`. VLAN 1 is removed from these ports. Confirm subinterface IDs match the trunk VLANs and the parent interface is up.

If setup fails partway through, inspect the trace, correct the reported command, clean up this lab, and rebuild. Setup uses `set -e` and is not idempotent; an interrupted run can leave namespaces or interfaces behind.
