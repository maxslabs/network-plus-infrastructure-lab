# Routing and Neighbour Inspection

I inspected PC-A's route and neighbour tables and the router's route table during the lab. The original table output is not included here. The listings below show the expected state from my verified addressing and setup script; they are not copied terminal output.

## PC-A Routes

```text
default via 10.10.10.1 dev veth-a
10.10.10.0/24 dev veth-a proto kernel scope link src 10.10.10.10
```

PC-A can send directly to its local subnet. Traffic for PC-C uses the default gateway `10.10.10.1`.

## PC-A Neighbour Table

After successful remote traffic, PC-A should have an ARP neighbour entry for `10.10.10.1` on `veth-a`. The entry maps the gateway IP to its MAC address. A gateway neighbour entry supports local next-hop delivery; it does not by itself prove forwarding or the remote return path.

PC-A does not need to ARP directly for `10.10.20.10` to send this routed traffic. Actual MAC addresses and states such as REACHABLE or STALE depend on the run and are not reconstructed here.

## Router Routes

```text
10.10.10.0/24 dev veth-rtr.10 proto kernel scope link src 10.10.10.1
10.10.20.0/24 dev veth-rtr.20 proto kernel scope link src 10.10.20.1
```

Both networks are directly connected. The router requires no default route for communication between them. IPv4 forwarding must also be enabled inside the router namespace.

Commands for fresh route and neighbour evidence are in [the evidence index](README.md).
