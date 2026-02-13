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
            local output_log="/tmp/kvkit_master_bootstrap.log"
            
            bootstrap_generate_base_script "$script" "$KV_RUNTIME" "$K8S_VERSION"
            bootstrap_generate_master_script "$script" "$KV_CNI"
            
            if ! bootstrap_ssh_run "$MASTER_DOMAIN" "$script" "$output_log"; then
                ui_error "Bootstrap failed on ${MASTER_DOMAIN}. See ${output_log} for details."
                exit 1
            fi
            bootstrap_remote_sync "$MASTER_DOMAIN"
            
            # Extract join command
            ui_info "Extracting join command..."
            local join_cmd=$(sed -n '/### KV_JOIN_START ###/,/### KV_JOIN_END ###/p' "$output_log" | grep "kubeadm join" | tr -d '\r' | xargs)
            
            if [ -n "$join_cmd" ]; then
                ui_success "Join command captured!"
                config_save "$K8S_VERSION" "$KV_RUNTIME" "$KV_CNI" "$MASTER_DOMAIN" "$WORKER_NODES" "$join_cmd"
            else
                ui_warn "Could not capture join command automatically. You may need to run 'kubeadm token create --print-join-command' on the master."
            fi
            ;;
        --local)
            if [ -z "$MASTER_DOMAIN" ]; then
                ui_error "No master domain found. Run 'kvkit config' first."
                exit 1
            fi
            bootstrap_local_setup "$MASTER_DOMAIN"
            ;;
        --worker)
            if [ -z "$JOIN_COMMAND" ]; then
                ui_error "Worker bootstrap requires a JOIN_COMMAND. Please bootstrap the master node first."
                exit 1
            fi

            ui_info "Bootstrapping Worker Nodes: ${WORKER_NODES}"
            for worker in $WORKER_NODES; do
                ui_info "Setting up worker: $worker"
                local script="/tmp/kvkit_worker_${worker}.sh"
                bootstrap_generate_base_script "$script" "$KV_RUNTIME" "$K8S_VERSION"
                bootstrap_generate_worker_script "$script" "$JOIN_COMMAND"
                if ! bootstrap_ssh_run "$worker" "$script"; then
                    ui_error "Bootstrap failed on worker: ${worker}"
                    exit 1
                fi
            done
            ;;
        *)
            ui_error "Invalid bootstrap option. Use --master or --worker."
            exit 1
            ;;
    esac
}
