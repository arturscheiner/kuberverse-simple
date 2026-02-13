#!/usr/bin/env bash

# Config Controller for kvkit

source "${LIB_DIR}/model/config.sh"

function config_execute() {
    ui_info "Starting kvkit configuration..."
    
    config_load

    local k8s_version=$(ui_ask "K8s Version" "${K8S_VERSION:-1.28.0}")
    
    local runtimes=("containerd" "cri-o" "docker")
    local runtime=$(ui_select "Select Container Runtime" "${runtimes[@]}")
    
    local cnis=("calico" "flannel" "cilium")
    local cni=$(ui_select "Select K8s CNI" "${cnis[@]}")
    
    local master_domain=$(ui_ask "Master node domain/IP" "${MASTER_DOMAIN:-ks-master-0}")
    local worker_nodes=$(ui_ask "Worker nodes (space separated)" "${WORKER_NODES:-ks-worker-0 ks-worker-1}")

    config_save "$k8s_version" "$runtime" "$cni" "$master_domain" "$worker_nodes"
    
    ui_success "Configuration saved to ${CONFIG_FILE}"
}
