function bootstrap_ssh_run() {
    local host="$1"
    local script="$2"
    local capture_file="$3"
    local remote_path="/tmp/kvkit_bootstrap.sh"
    
    ui_info "Transferring bootstrap script to ${host}..."
    scp -o StrictHostKeyChecking=no "$script" "${host}:${remote_path}"
    
    ui_info "Executing remote bootstrap on ${host}..."
    if [ -n "$capture_file" ]; then
        ssh -t -o StrictHostKeyChecking=no "$host" "sudo bash ${remote_path} && rm ${remote_path}" | tee "$capture_file"
    else
        ssh -t -o StrictHostKeyChecking=no "$host" "sudo bash ${remote_path} && rm ${remote_path}"
    fi
}

function bootstrap_remote_sync() {
    local host="$1"
    
    ui_info "Syncing configuration to remote host ${host}..."
    ssh -o StrictHostKeyChecking=no "$host" "mkdir -p ~/.kvkit"
    scp -o StrictHostKeyChecking=no "${CONFIG_FILE}" "${host}:~/.kvkit/config"
    
    # Optional: Clone repo to remote host
    ui_info "Setting up kvkit tools on remote host..."
    ssh -o StrictHostKeyChecking=no "$host" "mkdir -p ~/.kvkit/bin && if [ ! -d ~/.kvkit/bin/kuberverse-simple ]; then git clone https://github.com/arturscheiner/kuberverse-simple.git ~/.kvkit/bin/kuberverse-simple; else cd ~/.kvkit/bin/kuberverse-simple && git pull; fi"
}

function bootstrap_generate_base_script() {
    local script_path="$1"
    local runtime="$2"
    local version="$3"
    
    # Extract UI helpers from ui.sh (omitting the set -e and paths)
    local ui_helpers=$(cat "${LIB_DIR}/view/ui.sh" | grep -v "^source" | grep -v "^ROOT_DIR" | grep -v "^set -e")

    cat <<EOF > "$script_path"
#!/bin/bash
set -e

# UI Helpers
$ui_helpers

# Configuration variables injected from workstation
export K8S_VERSION="$version"
export KV_RUNTIME="$runtime"

# Cluster detection logic
ui_info "Checking if a Kubernetes control plane or tools are already installed..."
if command -v kubeadm >/dev/null 2>&1 && ([ -f /etc/kubernetes/admin.conf ] || kubectl get nodes >/dev/null 2>&1); then
    ui_success "Kubernetes detected. Skipping core installation."
    export KV_SKIP_INSTALL=true
else
    ui_info "No installation detected. Proceeding with full setup."
    export KV_SKIP_INSTALL=false
fi

# Core Setup (Skip if detected)
if [ "\$KV_SKIP_INSTALL" = "false" ]; then
    $(cat "${LIB_DIR}/modules/k8s_tools.sh")
    
    # Container Runtime Setup
    $(cat "${LIB_DIR}/modules/runtimes/${runtime}.sh")
fi
EOF
}

function bootstrap_generate_master_script() {
    local script_path="$1"
    local cni="$2"
    
    cat <<EOF >> "$script_path"

# User environment setup (Always refresh)
ui_info "Ensuring local user environment is configured..."
mkdir -p \$HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf \$HOME/.kube/config 2>/dev/null || true
sudo chown \$(id -u):\$(id -g) \$HOME/.kube/config 2>/dev/null || true

# Verify kubectl accessibility
if kubectl get nodes >/dev/null 2>&1; then
    ui_success "Environment validated: kubectl is operational."
else
    if [ "\$KV_SKIP_INSTALL" = "false" ]; then
        ui_info "Initializing Kubernetes control plane..."
        kubeadm init --ignore-preflight-errors=NumCPU
        
        # Re-run kubeconfig setup after init
        sudo cp -i /etc/kubernetes/admin.conf \$HOME/.kube/config
        sudo chown \$(id -u):\$(id -g) \$HOME/.kube/config
    else
        ui_error "Control plane should be running but kubectl access failed. Check node status."
    fi
fi

# CNI installation (only if not already there, but harmless to re-apply)
ui_info "Ensuring CNI: $cni"
$(cat "${LIB_DIR}/modules/cnis/${cni}.sh")

# Generate and print join command for capture
echo "### KV_JOIN_START ###"
kubeadm token create --print-join-command --ttl 0 2>/dev/null
echo "### KV_JOIN_END ###"
EOF
}

function bootstrap_generate_worker_script() {
    local script_path="$1"
    local join_command="$2"
    
    cat <<EOF >> "$script_path"

# Worker join logic
ui_info "Joining cluster..."
$join_command
EOF
}
