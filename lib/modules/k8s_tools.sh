#!/bin/bash

# Kubernetes Tools Installation Module (kubeadm, kubelet, kubectl).

KUBE_VERSION=${K8S_VERSION:-1.28}

echo "Installing Kubernetes tools (version: $KUBE_VERSION)..."

# Disable swap
swapoff -a
sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab

# Prepare terminal environment
if ! apt-get update; then
    ui_warn "apt-get update failed. This is often due to clock drift or network issues. Attempting to proceed anyway..."
fi
apt-get install -yq bash-completion binutils apt-transport-https ca-certificates curl gpg git

# Add Kubernetes repo
mkdir -p /etc/apt/keyrings
curl -fsSL https://pkgs.k8s.io/core:/stable:/v${KUBE_VERSION%.*}/deb/Release.key | gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v${KUBE_VERSION%.*}/deb/ /" | tee /etc/apt/sources.list.d/kubernetes.list

# Networking
modprobe br_netfilter
cat <<EOF | tee /etc/sysctl.d/99-kubernetes-cri.conf
net.bridge.bridge-nf-call-iptables  = 1
net.ipv4.ip_forward                 = 1
net.bridge.bridge-nf-call-ip6tables = 1
EOF
sysctl --system

# Final install
apt-get update
apt-get install -yq kubelet kubeadm kubectl kubernetes-cni
apt-mark hold kubelet kubeadm kubectl kubernetes-cni

systemctl enable --now kubelet
