#!/usr/bin/env bash
set -Eeuo pipefail

APP_NAME="Snck AI"
INSTALL_DIR="/opt/snck-ai"
REPO="https://github.com/SnckBoy/Ai-Snck.git"
UPSTREAM="https://github.com/danny-avila/LibreChat.git"

log(){ printf '\n[Snck AI] %s\n' "$*"; }
fail(){ echo "[Snck AI] ERROR: $*" >&2; exit 1; }

[[ $EUID -eq 0 ]] || fail "Run this installer as root (sudo -i or sudo bash ...)."

log "Installing prerequisites"
apt-get update
apt-get install -y git curl ca-certificates

if ! command -v docker >/dev/null 2>&1; then
  log "Installing Docker"
  curl -fsSL https://get.docker.com | sh
fi
systemctl enable --now docker

log "Preparing Snck AI"
rm -rf "$INSTALL_DIR"
git clone --depth 1 "$UPSTREAM" "$INSTALL_DIR"
cd "$INSTALL_DIR"

# Keep LibreChat's existing code and features intact; only apply the requested branding.
if [[ -f .env.example ]]; then cp .env.example .env; else touch .env; fi

set_env(){
  local key="$1" value="$2"
  if grep -qE "^${key}=" .env; then
    sed -i "s|^${key}=.*|${key}=${value}|" .env
  else
    printf '\n%s=%s\n' "$key" "$value" >> .env
  fi
}
set_env "APP_TITLE" "Snck AI"

log "Starting Docker services"
docker compose up -d --build

log "Installation complete"
echo
printf 'Snck AI is running at: http://%s:3080\n' "$(hostname -I | awk '{print $1}')"
printf 'Install directory: %s\n' "$INSTALL_DIR"
printf 'Manage: cd %s && docker compose ps\n' "$INSTALL_DIR"
