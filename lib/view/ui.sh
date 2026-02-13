#!/usr/bin/env bash

# UI Helpers for kvkit

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

function ui_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

function ui_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

function ui_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

function ui_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

function ui_ask() {
    local prompt="$1"
    local default="$2"
    local result

    if [ -n "$default" ]; then
        read -p "$(echo -e "${BLUE}??${NC} ${prompt} [${default}]: ")" result
        echo "${result:-$default}"
    else
        read -p "$(echo -e "${BLUE}??${NC} ${prompt}: ")" result
        echo "$result"
    fi
}

function ui_select() {
    local prompt="$1"
    shift
    local options=("$@")
    local result

    ui_info "$prompt"
    select opt in "${options[@]}"; do
        if [ -n "$opt" ]; then
            echo "$opt"
            break
        else
            ui_error "Invalid selection. Please try again."
        fi
    done
}
