#!/usr/bin/env bash
set -euo pipefail

if [[ $EUID -ne 0 ]]; then
  echo "Run as root (or via sudo)." >&2
  exit 1
fi

echo "[1/6] Packages"
dnf -y install \
  curl ca-certificates \
  iptables iptables-nft \
  socat conntrack-tools \
  iproute ipset \
  jq \
  nfs-utils \
  helm

echo "[2/6] Swap off (Kubernetes expects swap disabled)"
swapoff -a || true
if grep -qE '^\s*[^#].*\s+swap\s' /etc/fstab; then
  cp -a /etc/fstab "/etc/fstab.bak.$(date +%Y%m%d%H%M%S)"
  sed -i -E 's/^(\s*[^#].*\s+swap\s+.*)$/# \1/g' /etc/fstab
fi

echo "[3/6] Kernel modules"
cat >/etc/modules-load.d/k3s.conf <<'EOF'
br_netfilter
overlay
EOF
modprobe br_netfilter || true
modprobe overlay || true

echo "[4/6] Sysctls"
cat >/etc/sysctl.d/99-k3s.conf <<'EOF'
net.bridge.bridge-nf-call-iptables=1
net.bridge.bridge-nf-call-ip6tables=1
net.ipv4.ip_forward=1
EOF
sysctl --system >/dev/null

echo "[5/6] firewalld enabled"
systemctl enable --now firewalld >/dev/null || true

echo "[6/6] Done. Reboot if kernel modules/sysctls were changed."
