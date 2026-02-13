#!/usr/bin/env bash

# SSH management model for kvkit

function ssh_ensure_keys() {
    local key_file="${KV_KEY_PATH:-${HOME}/.kvkit/keys/id_ed25519}"
    local key_dir=$(dirname "$key_file")
    
    if [ ! -f "$key_file" ]; then
        ui_info "No dedicated KVKit SSH key found. Generating a new Ed25519 key pair..."
        mkdir -p "$key_dir"
        chmod 700 "$key_dir"
        ssh-keygen -t ed25519 -N "" -f "$key_file" >/dev/null
        ui_success "Dedicated key pair generated: $key_file"
    else
        ui_info "Dedicated KVKit SSH key found: $key_file"
    fi
}

function ssh_distribute_key() {
    local host="$1"
    local key_file="${KV_KEY_PATH:-${HOME}/.kvkit/keys/id_ed25519}.pub"
    
    if [ ! -f "$key_file" ]; then
        ui_error "Public key not found at $key_file"
        return 1
    fi

    local pub_key=$(cat "$key_file")
    
    ui_info "Sending public key to ${host}..."
    ui_info "Note: You may be prompted for the password of '${host}' once."
    
    # Manually append public key to authorized_keys
    if ssh -o StrictHostKeyChecking=no "$host" "mkdir -p ~/.ssh && chmod 700 ~/.ssh && echo '$pub_key' >> ~/.ssh/authorized_keys && chmod 600 ~/.ssh/authorized_keys"; then
        ui_success "Public key successfully sent to ${host}"
        return 0
    else
        ui_error "Failed to send public key to ${host}. Please check connectivity and credentials."
        return 1
    fi
}
