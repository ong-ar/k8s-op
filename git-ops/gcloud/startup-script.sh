#!/bin/bash
set -eux

# ============================================================================
# Kubernetes Node Initialization Script
# ============================================================================
# This script sets up a fresh Debian 12 system as a Kubernetes node.
# It configures the container runtime, networking, and installs Kubernetes
# components. The script is idempotent and will skip execution if already run.
# ============================================================================

MARKER_FILE="/var/lib/k8s-init.done"

# Skip if the script has already been executed once
if [ -f "$MARKER_FILE" ]; then
  echo "Kubernetes init script already executed. Skipping."
  exit 0
fi

echo "==== Kubernetes node first-time init start ===="

# ----------------------------------------------------------------------------
# System Preparation
# ----------------------------------------------------------------------------

# Update package lists and upgrade system packages
apt update
apt upgrade -y

# Disable swap (required by Kubernetes)
# Kubernetes requires swap to be disabled for proper memory management
swapoff -a
sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab

# ----------------------------------------------------------------------------
# Container Runtime Configuration (containerd)
# ----------------------------------------------------------------------------

# Configure crictl to use containerd as the container runtime
# crictl is a CLI for CRI-compatible container runtimes
cat >/etc/crictl.yaml <<EOF
runtime-endpoint: unix:///run/containerd/containerd.sock
image-endpoint: unix:///run/containerd/containerd.sock
timeout: 10
debug: false
EOF

# ----------------------------------------------------------------------------
# Network Configuration
# ----------------------------------------------------------------------------

# Required sysctl parameters for Kubernetes networking
# These settings enable proper packet forwarding and iptables integration
cat >/etc/sysctl.d/k8s.conf <<EOF
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF

# Apply sysctl parameters immediately
sysctl --system

# Load necessary kernel modules for container networking
# overlay: Required for overlay filesystem (used by containers)
# br_netfilter: Required for bridge networking with iptables
# iscsi_tcp: Required for iSCSI storage support (needed for persistent volumes)
cat >/etc/modules-load.d/k8s.conf <<EOF
overlay
br_netfilter
iscsi_tcp
EOF

# Load kernel modules immediately
modprobe overlay
modprobe br_netfilter
modprobe iscsi_tcp

# ----------------------------------------------------------------------------
# Install Container Runtime
# ----------------------------------------------------------------------------

# Install containerd and required dependencies
# open-iscsi: Required for iSCSI storage support (needed for persistent volumes)
apt install -y \
  ca-certificates \
  curl \
  gnupg \
  lsb-release \
  apt-transport-https \
  containerd \
  open-iscsi

# Backup any existing containerd config and generate a clean default
if [ -f /etc/containerd/config.toml ]; then
  mv /etc/containerd/config.toml /etc/containerd/config.toml.bak
fi
containerd config default > /etc/containerd/config.toml

# Enable SystemdCgroup (required by kubelet)
# This ensures containerd uses systemd cgroup driver, matching kubelet
sed -i 's/SystemdCgroup = false/SystemdCgroup = true/g' /etc/containerd/config.toml
systemctl restart containerd

# ----------------------------------------------------------------------------
# Install Kubernetes Components
# ----------------------------------------------------------------------------

# Add the Kubernetes APT repository
# Using Kubernetes v1.34 stable repository
mkdir -p /etc/apt/keyrings
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.34/deb/Release.key \
  | gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
chmod 644 /etc/apt/keyrings/kubernetes-apt-keyring.gpg

cat >/etc/apt/sources.list.d/kubernetes.list <<EOF
deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.34/deb/ /
EOF
chmod 644 /etc/apt/sources.list.d/kubernetes.list

# Update package lists and install Kubernetes components
apt update
apt install -y kubelet kubeadm kubectl

# Prevent the installed versions from being automatically upgraded
# This ensures version stability and prevents unexpected updates
apt-mark hold kubelet kubeadm kubectl

# ----------------------------------------------------------------------------
# Enable Services
# ----------------------------------------------------------------------------

# Enable and start required services
# kubelet: Kubernetes node agent
# containerd: Container runtime
# iscsid: iSCSI daemon (required for persistent volume support)
systemctl enable --now kubelet
systemctl enable --now containerd
systemctl enable --now iscsid

# ----------------------------------------------------------------------------
# Finalization
# ----------------------------------------------------------------------------

# Create marker file to ensure this script only runs once
mkdir -p /var/lib
touch "$MARKER_FILE"

echo "==== Kubernetes node first-time init done ===="
