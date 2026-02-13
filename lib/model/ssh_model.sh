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
    
    # Use ssh-copy-id for standard compliant key distribution
    ui_info "Step 1: Distributing dedicated public key using ssh-copy-id..."
    if ! ssh-copy-id -i "${key_file}" -o StrictHostKeyChecking=no "${host}"; then
        ui_error "Failed to send public key using ssh-copy-id to ${host}. Please check connectivity and credentials."
        return 1
    fi

    # Step 2: Configure passwordless sudo for current user using the dedicated key
    local remote_user=$(whoami)
    ui_info "Step 2: Configuring passwordless sudo for ${remote_user} on ${host}..."
    
    # Use -t to ensure a terminal is allocated for the sudo password prompt
    # Use -o IdentitiesOnly=yes to ensure we use the dedicated key we just sent
    if ssh -i "${KV_KEY_PATH}" -t -o StrictHostKeyChecking=no -o IdentitiesOnly=yes "$host" "echo '$remote_user ALL=(ALL) NOPASSWD:ALL' | sudo tee /etc/sudoers.d/kvkit-$(whoami) >/dev/null && sudo chmod 440 /etc/sudoers.d/kvkit-$(whoami)"; then
        ui_success "Key distribution and sudo automation complete for ${host}"
        return 0
    else
        ui_error "Failed to configure passwordless sudo on ${host}."
        return 1
    fi
}
