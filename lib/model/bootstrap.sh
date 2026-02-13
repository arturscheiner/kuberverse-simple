#!/usr/bin/env bash

# Bootstrap Model for kvkit

function bootstrap_ssh_run() {
    local host="$1"
    local script="$2"
    
    ui_info "Executing remote bootstrap on ${host}..."
    ssh -o StrictHostKeyChecking=no "$host" "sudo bash -s" < "$script"
}

function bootstrap_generate_base_script() {
    local script_path="$1"
    local runtime="$2"
    local version="$3"
    
    cat <<EOF > "$script_path"
#!/bin/bash
set -e

# Configuration variables injected from workstation
export K8S_VERSION="$version"
export KV_RUNTIME="$runtime"

# Core Setup
$(cat "${LIB_DIR}/modules/k8s_tools.sh")

# Container Runtime Setup
$(cat "${LIB_DIR}/modules/runtimes/${runtime}.sh")
EOF
}

function bootstrap_generate_master_script() {
    local script_path="$1"
    local cni="$2"
    
    cat <<EOF >> "$script_path"

# Master initialization logic
ui_info "Initializing Kubernetes control plane..."
kubeadm init --ignore-preflight-errors=NumCPU

mkdir -p \$HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf \$HOME/.kube/config
sudo chown \$(id -u):\$(id -g) \$HOME/.kube/config

# CNI installation
ui_info "Installing CNI: $cni"
$(cat "${LIB_DIR}/modules/cnis/${cni}.sh")
EOF
}
