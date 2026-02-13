#!/usr/bin/env bash

# Config Controller for kvkit

source "${LIB_DIR}/model/config.sh"
source "${LIB_DIR}/model/ssh_model.sh"

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
    local cluster_domain=$(ui_ask "Cluster local domain" "${CLUSTER_DOMAIN:-cluster.local}")

    config_save "$k8s_version" "$runtime" "$cni" "$master_domain" "$worker_nodes" "$cluster_domain"
    
    ui_success "Configuration saved to ${CONFIG_FILE}"

    # SSH key automation
    local do_ssh=$(ui_ask "Would you like to generate and distribute SSH keys to all nodes automatically? (y/n)" "y")
    if [[ "$do_ssh" =~ ^[Yy]$ ]]; then
        ssh_ensure_keys
        
        ui_info "Distributing keys to master: ${master_domain}"
        ssh_distribute_key "${master_domain}"
        
        for worker in $worker_nodes; do
            ui_info "Distributing keys to worker: ${worker}"
            ssh_distribute_key "${worker}"
        done
        
        ui_success "SSH key distribution phase complete."
    fi
}
