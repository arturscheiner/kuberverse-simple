#!/usr/bin/env bash

# Bootstrap Controller for kvkit

source "${LIB_DIR}/model/config.sh"
source "${LIB_DIR}/model/bootstrap.sh"

function bootstrap_execute() {
    local node_type="$1"
    
    config_load
    
    if [ -z "$KV_RUNTIME" ]; then
        ui_error "No configuration found. Please run 'kvkit config' first."
        exit 1
    fi

    case "$node_type" in
        --master)
            ui_info "Bootstrapping Master Node: ${MASTER_DOMAIN}"
            local script="/tmp/kvkit_master.sh"
            bootstrap_generate_base_script "$script" "$KV_RUNTIME" "$K8S_VERSION"
            bootstrap_generate_master_script "$script" "$KV_CNI"
            bootstrap_ssh_run "$MASTER_DOMAIN" "$script"
            ;;
        --worker)
            ui_info "Bootstrapping Worker Nodes: ${WORKER_NODES}"
            for worker in $WORKER_NODES; do
                ui_info "Setting up worker: $worker"
                local script="/tmp/kvkit_worker_${worker}.sh"
                bootstrap_generate_base_script "$script" "$KV_RUNTIME" "$K8S_VERSION"
                # Join logic would go here (requires join command from master)
                bootstrap_ssh_run "$worker" "$script"
            done
            ;;
        *)
            ui_error "Invalid bootstrap option. Use --master or --worker."
            exit 1
            ;;
    esac
}
