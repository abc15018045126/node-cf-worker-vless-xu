#!/bin/bash

# This script sets up a Node.js application with a Cloudflare tunnel.
# It can be run interactively or with command-line arguments for automation.
#
# INTERACTIVE USAGE:
#   bash 1.txt
#
# COMMAND-LINE USAGE:
#   For a temporary tunnel:
#   bash 1.txt --type temporary [--port <port>] [--id <uuid>]
#
#   For a fixed Argo tunnel:
#   bash 1.txt --type fixed [--port <port>] [--id <uuid>] --agn <domain> --agk <token>
#
# Arguments:
#   --type      : Tunnel type. 'temporary' or 'fixed'.
#   --port      : Port number (optional, defaults will be used).
#   --id        : UUID (optional, defaults will be used).
#   --agn       : Argo domain (required for fixed tunnel).
#   --agk       : Argo JSON token (required for fixed tunnel).

# --- Configuration ---
# Default values used if not provided via command-line or interactively.
DEFAULT_PORT="13727"
DEFAULT_ID="2ea73714-138e-4cc7-8cab-d7caf476d51b"
DEFAULT_ARGO_DOMAIN="githubvps.abc15018045126.dpdns.org"
DEFAULT_ARGO_TOKEN="eyJhIjoiMGU2MDk0M2E3YjM5Yzk5OTQyMTY5MmQ0ODg2ZWFlNTQiLCJ0IjoiZTAxMWU2N2ItMjE3MS00ZmQ1LWIxYTYtZjRiNDU4MTVkMWNiIiwicyI6Ik56UXdPVFUzTm1NdE1tTmhPQzAwWm1JMkxXSXdaVE10TWpReVlqUmhNekJoWWpKaiJ9"
INTERACTIVE_MODE=true

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
    if [ "$INTERACTIVE_MODE" = true ]; then
        read -p "Press Enter to continue, or Ctrl+C to cancel."
    fi
    
    echo "Starting setup... This may take a few minutes."
    # Export variables for the setup script
    export PORT ID agn agk
    bash <(curl -Ls https://raw.githubusercontent.com/abc15018045126/node-cf-worker-deno-vless-xu/main/setup.sh)
}

# --- Argument Parsing ---
# Override defaults with any command-line arguments provided.
while [[ $# -gt 0 ]]; do
    key="$1"
    case $key in
        --type)
        TUNNEL_TYPE="$2"
        INTERACTIVE_MODE=false
        shift; shift
        ;;
        --port)
        PORT_OVERRIDE="$2"
        shift; shift
        ;;
        --id)
        ID_OVERRIDE="$2"
        shift; shift
        ;;
        --agn)
        AGN_OVERRIDE="$2"
        shift; shift
        ;;
        --agk)
        AGK_OVERRIDE="$2"
        shift; shift
        ;;
        *)    # unknown option
        echo "Unknown option: $1"
        exit 1
        ;;
    esac
done

# --- Main Script ---
if [ "$INTERACTIVE_MODE" = true ]; then
    # --- Interactive Mode ---
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
else
    # --- Non-Interactive (Command-Line) Mode ---
    echo "Running in non-interactive mode..."
    
    # Set variables using overrides or defaults
    export PORT=${PORT_OVERRIDE:-$DEFAULT_PORT}
    export ID=${ID_OVERRIDE:-$DEFAULT_ID}
    
    if [ "$TUNNEL_TYPE" == "fixed" ]; then
        export agn=${AGN_OVERRIDE:-$DEFAULT_ARGO_DOMAIN}
        export agk=${AGK_OVERRIDE:-$DEFAULT_ARGO_TOKEN}
        if [[ -z "$agn" || -z "$agk" ]]; then
            echo "Error: For fixed tunnel type, --agn and --agk are required."
            exit 1
        fi
    elif [ "$TUNNEL_TYPE" == "temporary" ]; then
        unset agn
        unset agk
    else
        echo "Error: Invalid or missing tunnel type. Use --type 'temporary' or 'fixed'."
        exit 1
    fi
    
    run_setup
fi

echo ""
echo "Setup process has been initiated."
