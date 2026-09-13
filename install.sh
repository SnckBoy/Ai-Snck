#!/usr/bin/env bash
set -euo pipefail

APP_NAME="Snck AI"
INSTALL_DIR="/opt/snck-ai"
REPO_RAW="https://raw.githubusercontent.com/SnckBoy/Ai-Snck/main/LibreChat-main.zip"
TMP_DIR="$(mktemp -d)"
ZIP_FILE="$TMP_DIR/snck-ai.zip"

cleanup() { rm -rf "$TMP_DIR"; }
trap cleanup EXIT

if [[ $EUID -ne 0 ]]; then
  echo "Please run this installer as root."
  exit 1
fi

echo "==> Installing $APP_NAME dependencies..."
export DEBIAN_FRONTEND=noninteractive
apt-get update -y
apt-get install -y curl unzip ca-certificates git

if ! command -v node >/dev/null 2>&1; then
  echo "==> Installing Node.js 20..."
  curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
  apt-get install -y nodejs
fi

if ! command -v npm >/dev/null 2>&1; then
  apt-get install -y npm
fi

echo "==> Downloading Snck AI source..."
curl -fL "$REPO_RAW" -o "$ZIP_FILE"

rm -rf "$INSTALL_DIR"
mkdir -p "$INSTALL_DIR"
unzip -q "$ZIP_FILE" -d "$TMP_DIR/extracted"
SOURCE_DIR="$TMP_DIR/extracted/LibreChat-main"

if [[ ! -d "$SOURCE_DIR" ]]; then
  echo "Installer error: expected LibreChat-main directory was not found in the archive."
  exit 1
fi

cp -a "$SOURCE_DIR/." "$INSTALL_DIR/"

# Brand user-facing text without changing application structure or functionality.
find "$INSTALL_DIR" -type f \( -name '*.js' -o -name '*.jsx' -o -name '*.ts' -o -name '*.tsx' -o -name '*.json' -o -name '*.html' -o -name '*.md' -o -name '*.css' -o -name '*.scss' -o -name '*.yml' -o -name '*.yaml' \) -print0 |
while IFS= read -r -d '' file; do
  if grep -Iq . "$file" 2>/dev/null; then
    sed -i 's/LibreChat/Snck AI/g; s/LIBRECHAT/SNCK AI/g; s/Libre Chat/Snck AI/g' "$file" || true
  fi
done

cd "$INSTALL_DIR"

if [[ -f package.json ]]; then
  echo "==> Installing Node dependencies..."
  npm install
fi

cat > /usr/local/bin/snck-ai <<'EOF'
#!/usr/bin/env bash
cd /opt/snck-ai
exec npm run start -- "$@"
EOF
chmod +x /usr/local/bin/snck-ai

cat > /etc/profile.d/snck-ai.sh <<'EOF'
export SNCK_AI_DIR=/opt/snck-ai
EOF

echo
 echo "========================================"
echo "  Snck AI installation complete"
echo "========================================"
echo "Location: $INSTALL_DIR"
echo "Start:    cd $INSTALL_DIR && npm run start"
echo "Command:  snck-ai"
echo
