#!/bin/bash

# This script sets up a Node.js application with a Cloudflare tunnel.
# It automatically detects the system architecture (x86_64 or aarch64) and distribution (Debian/CentOS based).

# --- Configuration ---
# You can modify the default values below or enter them when prompted.
DEFAULT_PORT="13727"
DEFAULT_ID="2ea73714-138e-4cc7-8cab-d7caf476d51b"
DEFAULT_ARGO_DOMAIN="githubvps.abc15018045126.dpdns.org"
DEFAULT_ARGO_TOKEN="eyJhIjoiMGU2MDk0M2E3YjM5Yzk5OTQyMTY5MmQ0ODg2ZWFlNTQiLCJ0IjoiZTAxMWU2N2ItMjE3MS00ZmQ1LWIxYTYtZjRiNDU4MTVkMWNiIiwicyI6Ik56UXdPVFUzTm1NdE1tTmhPQzAwWm1JMkxXSXdaVE10TWpReVlqUmhNekJoWWpKaiJ9"

# --- Functions ---
run_setup() {
    echo ""
    echo "The following settings will be used:"
    echo "PORT: $PORT"
    echo "ID: $ID"
    if [ "$TUNNEL_TYPE" == "fixed" ]; then
        echo "Argo Domain: $agn"
        echo "Argo Token: [hidden]"
    else
        echo "Tunnel Type: Temporary"
    fi
    
    echo ""
    read -p "Press Enter to continue, or Ctrl+C to cancel."
    
    echo "Starting setup... This may take a few minutes."
    # Export variables for the setup script
    export PORT ID agn agk
    bash <(curl -Ls https://raw.githubusercontent.com/abc15018045126/node-cf-worker-deno-vless-xu/main/setup.sh)
}

# --- Main Script ---
clear
echo "======================================================"
echo " Cloudflare Tunnel & Node.js Application Setup Script"
echo "======================================================"
echo "This script will guide you through setting up your application."
echo ""

echo "Choose a tunnel type:"
echo "  1) Temporary Tunnel (Easy setup, URL changes on each run)"
echo "  2) Fixed Argo Tunnel (Persistent URL, requires Cloudflare account)"
echo ""
read -p "Enter your choice [1-2]: " choice

# Set common variables
export PORT="$DEFAULT_PORT"
export ID="$DEFAULT_ID"

case $choice in
    1)
        TUNNEL_TYPE="temporary"
        # Unset argo variables for temporary tunnel
        unset agn
        unset agk
        run_setup
        ;;
    2)
        TUNNEL_TYPE="fixed"
        echo ""
        echo "--- Fixed Argo Tunnel Configuration ---"
        read -p "Enter your Argo domain [${DEFAULT_ARGO_DOMAIN}]: " agn
        agn=${agn:-$DEFAULT_ARGO_DOMAIN}

        echo "Enter your Argo JSON token."
        read -p "[press Enter to use the default token]: " agk
        agk=${agk:-$DEFAULT_ARGO_TOKEN}

        if [[ -z "$agn" || -z "$agk" ]]; then
            echo "Error: Argo domain and token are required for a fixed tunnel."
            exit 1
        fi
        
        run_setup
        ;;
    *)
        echo "Invalid choice. Exiting."
        exit 1
        ;;
esac

echo ""
echo "Setup process has been initiated."
