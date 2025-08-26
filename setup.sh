#!/bin/bash
set -e

### --- Input Parameters ---
PORT=${PORT:-3000}   # default port
ID=${ID:-"default-id"}
AGN=${agn:-""}       # Cloudflare domain name
AGK=${agk:-""}       # Cloudflare token/credentials

### --- Detect architecture ---
ARCH=$(uname -m)
case "$ARCH" in
  x86_64) ARCH="amd64" ;;
  aarch64) ARCH="arm64" ;;
  *) echo "Unsupported architecture: $ARCH"; exit 1 ;;
esac

### --- Detect package manager ---
if command -v apt-get >/dev/null 2>&1; then
  PM="apt-get"
elif command -v dnf >/dev/null 2>&1; then
  PM="dnf"
elif command -v yum >/dev/null 2>&1; then
  PM="yum"
elif command -v pacman >/dev/null 2>&1; then
  PM="pacman"
else
  echo "No supported package manager found."
  exit 1
fi

echo "[*] Architecture: $ARCH"
echo "[*] Package manager: $PM"

### --- Install curl and xz ---
case "$PM" in
  apt-get) sudo $PM update && sudo $PM install -y curl xz-utils ;;
  dnf|yum) sudo $PM install -y curl xz ;;
  pacman) sudo $PM -Sy --noconfirm curl xz ;;
esac

### --- Install Node.js ---
NODE_VERSION="22.5.1"
NODE_DIR="$HOME/node"
mkdir -p "$NODE_DIR"
cd "$NODE_DIR"

if [ ! -x "$NODE_DIR/bin/node" ]; then
  echo "[*] Installing Node.js v$NODE_VERSION..."
  curl -fsSL "https://nodejs.org/dist/v$NODE_VERSION/node-v$NODE_VERSION-linux-$ARCH.tar.xz" -o node.tar.xz
  tar -xJf node.tar.xz --strip-components=1
  rm node.tar.xz
fi

export PATH="$NODE_DIR/bin:$PATH"
echo 'export PATH="$HOME/node/bin:$PATH"' >> ~/.bashrc

### --- Download project files ---
cd "$HOME"
curl -fsSL -o package.json https://raw.githubusercontent.com/abc15018045126/node-cf-worker-deno-vless-xu/main/package.json
curl -fsSL -o index.js https://raw.githubusercontent.com/abc15018045126/node-cf-worker-deno-vless-xu/main/index.js

### --- Write env variables ---
cat > .env <<EOF
PORT=$PORT
ID=$ID
EOF

### --- Install dependencies ---
npm install

### --- Run Node app in background ---
nohup node index.js > app.log 2>&1 &
echo "[*] Node app running on localhost:$PORT"

### --- Install cloudflared ---
if [ ! -x /usr/local/bin/cloudflared ]; then
  echo "[*] Installing cloudflared..."
  curl -fsSL -o cloudflared-linux-$ARCH.tgz "https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-$ARCH.tgz"
  tar -xzf cloudflared-linux-$ARCH.tgz
  sudo mv cloudflared /usr/local/bin/
  rm cloudflared-linux-$ARCH.tgz
fi

### --- Run Argo tunnel ---
if [ -n "$AGN" ] && [ -n "$AGK" ]; then
  echo "[*] Starting fixed Argo tunnel for $AGN..."
  mkdir -p ~/.cloudflared
  echo "$AGK" > ~/.cloudflared/$AGN.json
  cat > ~/.cloudflared/config.yml <<EOF
tunnel: $AGN
credentials-file: /root/.cloudflared/$AGN.json
ingress:
  - hostname: $AGN
    service: http://localhost:$PORT
  - service: http_status:404
EOF
  nohup cloudflared tunnel run $AGN > tunnel.log 2>&1 &
  echo "[*] Fixed tunnel started: https://$AGN"
else
  echo "[*] Starting temporary Argo tunnel..."
  cloudflared tunnel --url http://localhost:$PORT
fi
