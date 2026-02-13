#!/usr/bin/env bash

# Bootstrap Model for kvkit

function bootstrap_ssh_run() {
    local host="$1"
    local script="$2"
    
    ui_info "Executing remote bootstrap on ${host}..."
    ssh -o StrictHostKeyChecking=no "$host" "bash -s" < "$script"
}

function bootstrap_generate_base_script() {
    local script_path="$1"
    local runtime="$2"
    
    cat <<EOF > "$script_path"
#!/bin/bash
set -e
# Base setup logic for \$runtime
$(cat "${LIB_DIR}/modules/runtimes/${runtime}.sh")
EOF
}

function bootstrap_generate_master_script() {
    local script_path="$1"
    local cni="$2"
    
    cat <<EOF >> "$script_path"
# Master initialization logic
kubeadm init --ignore-preflight-errors=NumCPU
mkdir -p \$HOME/.kube
cp -i /etc/kubernetes/admin.conf \$HOME/.kube/config
chown \$(id -u):\$(id -g) \$HOME/.kube/config

# CNI installation
$(cat "${LIB_DIR}/modules/cnis/${cni}.sh")
EOF
}
