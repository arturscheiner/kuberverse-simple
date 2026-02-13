#!/usr/bin/env bash

# Config Model for kvkit

CONFIG_DIR="${HOME}/.kvkit"
CONFIG_FILE="${CONFIG_DIR}/config"

function config_load() {
    if [ -f "$CONFIG_FILE" ]; then
        source "$CONFIG_FILE"
    fi
}

function config_save() {
    local k8s_version="$1"
    local runtime="$2"
    local cni="$3"
    local master_domain="$4"
    local worker_nodes="$5"
    local join_command="$6"

    mkdir -p "$CONFIG_DIR"
    {
        echo "K8S_VERSION=\"$k8s_version\""
        echo "KV_RUNTIME=\"$runtime\""
        echo "KV_CNI=\"$cni\""
        echo "MASTER_DOMAIN=\"$master_domain\""
        echo "WORKER_NODES=\"$worker_nodes\""
        [ -z "$join_command" ] || echo "JOIN_COMMAND=\"$join_command\""
    } > "$CONFIG_FILE"
}
