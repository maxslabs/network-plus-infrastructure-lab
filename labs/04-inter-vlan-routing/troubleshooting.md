# Lab 04 Troubleshooting Notes

## IPv4 Forwarding Disabled

**Symptom:** Inter-VLAN traffic failed after deliberately setting forwarding to `0` in the router namespace.

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

The supplied completed-session observation records failure at `0` and recovery at `1`. No raw failure transcript is retained. To repeat the deliberate fault on this lab, set `net.ipv4.ip_forward=0` with the same namespace-scoped command, test, then restore it to `1` before continuing.

## Missing veth Type in Setup

**Symptom:** The shell trace stopped while creating PC-C, then PC-D, with:

```text
Garbage instead of arguments "name ...". Try "ip link help".
```

**Investigation:** `sudo bash -x ./scripts/setup.sh` identified commands using `type peer` instead of `type veth peer`.

**Root cause:** The interface type argument `veth` was missing.

**Resolution:** Max corrected both lines:

```bash
ip link add veth-c type veth peer name veth-c-br
ip link add veth-d type veth peer name veth-d-br
```

The partial topology was cleaned before rerunning setup. The final trace reached “Lab 04 setup complete”, and the subsequent PC-A to PC-C ping returned two replies with no loss. The existing scripts retain these corrections.

## VLAN Filtering and Membership Checks

The session handoff mentions additional VLAN-filtering and script debugging without retaining the exact earlier error transcripts. The checks below describe the verified final configuration; they do not assert an undocumented historical root cause.

```bash
sudo ip -d link show br0
sudo bridge vlan show
sudo ip netns exec router ip -d link show veth-rtr.10
sudo ip netns exec router ip -d link show veth-rtr.20
```

Verify `vlan_filtering 1`; VLAN 10 with PVID and Egress Untagged on `veth-a-br`/`veth-b-br`; VLAN 20 with those flags on `veth-c-br`/`veth-d-br`; and VLANs 10/20 without untagged flags on `veth-rtr-br`. VLAN 1 is removed from these ports. Confirm subinterface IDs match the trunk VLANs and the parent interface is up.

If setup fails partway through, inspect the trace, correct the reported command, clean up this lab, and rebuild. Setup uses `set -e` and is not idempotent; an interrupted run can leave namespaces or interfaces behind.
