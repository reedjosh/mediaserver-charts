# Control-plane static pods (NOT Argo-managed)

These are node-local static pods placed in `/etc/kubernetes/manifests/` on the
**control-plane node(s)** — kept here for version control, deployed by hand.

## kube-vip.yaml
HA API VIP via kube-vip in **ARP/L2** mode. VIP **192.168.50.10:6443**, interface `eno1`,
`--controlplane --arp --leaderElection`. CNI/router-independent (hostNetwork, comes up before
Cilium). Copy to `/etc/kubernetes/manifests/kube-vip.yaml` on EACH control-plane node (same file
— leaderElection floats the VIP to the current leader). See ~/etcd-ha-control-plane-runbook.md.
