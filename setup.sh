#!/bin/bash

# ==============================================================================
# Full Setup & Execution Script for Node.js App with Cloudflare Tunnel
# ==============================================================================
# This script automates the entire process on a Debian-based Linux system:
# 1.  Installs prerequisites: Node.js, npm, and cloudflared.
# 2.  Downloads and sets up the Node.js application.
# 3.  Launches the application with either a temporary or fixed Cloudflare tunnel.
#
# --- Instructions ---
# 1.  Customize the configuration variables below if needed.
# 2.  Choose your tunnel type in Step 5 at the end of the script.
# 3.  Run the script: `bash 1.txt`
# ==============================================================================

set -e

# --- Step 1: Configuration ---
# Customize these variables for your setup.
# These are used for both temporary and fixed tunnels.
export PORT="13727"
export ID="2ea73714-138e-4cc7-8cab-d7caf476d51b"

# These are ONLY for the fixed Argo tunnel.
export agn="githubvps.abc15018045126.dpdns.org"
export agk="eyJhIjoiMGU2MDk0M2E3YjM5Yzk5OTQyMTY5MmQ0ODg2ZWFlNTQiLCJ0IjoiZTAxMWU2N2ItMjE3MS00ZmQ1LWIxYTYtZjRiNDU4MTVkMWNiIiwicyI6Ik56UXdPVFUzTm1NdE1tTmhPQzAwWm1JMkxXSXdaVE10TWpReVlqUmhNekJoWWpKaiJ9"

# --- Step 2: Install Prerequisites ---
echo "Updating package lists..."
sudo apt-get update

echo "Installing Node.js, npm, and curl..."
sudo apt-get install -y nodejs npm curl

# --- Step 3: Setup Cloudflare Repository and Install cloudflared ---
echo "Setting up Cloudflare repository..."
sudo mkdir -p --mode=0755 /usr/share/keyrings
curl -fsSL https://pkg.cloudflare.com/cloudflare-main.gpg | sudo tee /usr/share/keyrings/cloudflare-main.gpg >/dev/null
echo 'deb [signed-by=/usr/share/keyrings/cloudflare-main.gpg] https://pkg.cloudflare.com/cloudflared any main' | sudo tee /etc/apt/sources.list.d/cloudflared.list

echo "Installing cloudflared..."
sudo apt-get update && sudo apt-get install -y cloudflared

# --- Step 4: Download and Setup Node.js Application ---
echo "Downloading application files..."
curl -o package.json https://raw.githubusercontent.com/abc15018045126/node-cf-worker-deno-vless-xu/main/package.json
curl -o index.js https://raw.githubusercontent.com/abc15018045126/node-cf-worker-deno-vless-xu/main/index.js

echo "Installing Node.js dependencies..."
npm install

# --- Step 5: Run the Application with a Cloudflare Tunnel ---
# The remote setup.sh script handles architecture detection (x86/arm).
#
# Choose ONE of the following options.
# By default, the temporary tunnel is enabled.

# --- Option A: Temporary Tunnel (Enabled by default) ---
echo "Starting with a temporary tunnel..."
bash <(curl -Ls https://raw.githubusercontent.com/abc15018045126/node-cf-worker-deno-vless-xu/main/setup.sh)

# --- Option B: Fixed Argo Tunnel (Disabled by default) ---
# To use this, comment out the line in "Option A" above and uncomment the line below.
#
# echo "Starting with a fixed Argo tunnel..."
# bash <(curl -Ls https://raw.githubusercontent.com/abc15018045126/node-cf-worker-deno-vless-xu/main/setup.sh)

echo "Setup is complete and the service should be running."
