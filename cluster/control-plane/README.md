# Control-plane static pods (NOT Argo-managed)

These are node-local static pods placed in `/etc/kubernetes/manifests/` on the
**control-plane node(s)** — kept here for version control, deployed by hand.

## kube-vip.yaml
HA API VIP via kube-vip in **ARP/L2** mode. VIP **192.168.50.10:6443**, interface `eno1`,
`--controlplane --arp --leaderElection`. CNI/router-independent (hostNetwork, comes up before
Cilium). Copy to `/etc/kubernetes/manifests/kube-vip.yaml` on EACH control-plane node (same file
— leaderElection floats the VIP to the current leader). See ~/etcd-ha-control-plane-runbook.md.

## Cold-boot hardening (kube-vip.conf)
Each CP node also has `/etc/kubernetes/kube-vip.conf` — a copy of admin.conf with the
server pointed at THAT node's own apiserver IP (not the VIP). The kube-vip manifest mounts
it, so every node's kube-vip can reach an apiserver and bootstrap the VIP independently —
no single anchor node on a cold start. Recreate per node if rebuilt:
  sudo sed 's#server: https://[0-9.]*:6443#server: https://<NODE_IP>:6443#' \
    /etc/kubernetes/admin.conf | sudo tee /etc/kubernetes/kube-vip.conf
