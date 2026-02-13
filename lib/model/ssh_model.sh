#!/usr/bin/env bash

# SSH management model for kvkit

function ssh_ensure_keys() {
    local key_file="${HOME}/.ssh/id_ed25519"
    
    if [ ! -f "$key_file" ]; then
        ui_info "No SSH key found. Generating a new Ed25519 key pair..."
        mkdir -p "${HOME}/.ssh"
        chmod 700 "${HOME}/.ssh"
        ssh-keygen -t ed25519 -N "" -f "$key_file" >/dev/null
        ui_success "Key pair generated: $key_file"
    else
        ui_info "Existing SSH key found: $key_file"
    fi
}

function ssh_distribute_key() {
    local host="$1"
    
    ui_info "Sending public key to ${host}..."
    ui_info "Note: You may be prompted for the password of '${host}' once."
    
    # Use ssh-copy-id with StrictHostKeyChecking=no to avoid being blocked by host validation
    if ssh-copy-id -o StrictHostKeyChecking=no "$host"; then
        ui_success "Public key successfully sent to ${host}"
        return 0
    else
        ui_error "Failed to send public key to ${host}. Please check connectivity and credentials."
        return 1
    fi
}
