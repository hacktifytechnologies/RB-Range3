#!/usr/bin/env bash
# =============================================================================
# setup.sh — M2 · dev-registry · RNG-DEV-01 · VIKAS TANTRA
# Challenge: Unauthenticated Docker Registry v2 API + Credentials in Image Config
# MITRE: T1552.001 · T1613
# Ubuntu 22.04 — NO internet required
# =============================================================================
set -euo pipefail

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; NC='\033[0m'
log()  { echo -e "${GREEN}[SETUP]${NC} $*"; }
info() { echo -e "${CYAN}[INFO]${NC}  $*"; }
warn() { echo -e "${YELLOW}[WARN]${NC}  $*"; }
fail() { echo -e "${RED}[FAIL]${NC}  $*"; exit 1; }

[[ $EUID -ne 0 ]] && fail "Run as root"
python3 -c "import flask" 2>/dev/null || fail "Flask not found — run deps.sh first"

log "=== M2 · dev-registry setup starting ==="

APP_DIR="/opt/pul-registry"
APP_USER="pul-registry"
LOG_DIR="/var/log/pul-registry"

# ── User and directories ───────────────────────────────────────────────────────
id "$APP_USER" &>/dev/null || useradd -r -s /bin/false -d "$APP_DIR" "$APP_USER"
mkdir -p "$APP_DIR/app/templates" "$LOG_DIR"

# ── Copy app files ──────────────────────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
log "Installing application files..."
cp -r "$SCRIPT_DIR/app/"* "$APP_DIR/app/"

# ── Start script ──────────────────────────────────────────────────────────────
cat > "$APP_DIR/start.sh" << 'SH'
#!/usr/bin/env bash
cd /opt/pul-registry/app
exec python3 app.py
SH
chmod +x "$APP_DIR/start.sh"

# ── Systemd service ───────────────────────────────────────────────────────────
log "Creating systemd service..."
cat > /etc/systemd/system/pul-registry.service << SVC
[Unit]
Description=PUL Container Registry — NEXUS-IT
After=network.target
[Service]
Type=simple
User=${APP_USER}
WorkingDirectory=${APP_DIR}/app
ExecStart=/usr/bin/python3 ${APP_DIR}/app/app.py
Restart=always
RestartSec=5
StandardOutput=journal
StandardError=journal
SyslogIdentifier=pul-registry
[Install]
WantedBy=multi-user.target
SVC

# ── Ownership and permissions ──────────────────────────────────────────────────
chown -R "$APP_USER:$APP_USER" "$APP_DIR" "$LOG_DIR"
chmod 755 "$APP_DIR"

# ── Hostname ───────────────────────────────────────────────────────────────────
echo "registry.prabalurja.in" > /etc/hostname
hostname registry.prabalurja.in 2>/dev/null || true

# ── Start service ──────────────────────────────────────────────────────────────
log "Starting pul-registry service..."
systemctl daemon-reload
systemctl enable pul-registry
systemctl start pul-registry
sleep 3

if systemctl is-active --quiet pul-registry; then
    log "Service UP"
else
    warn "Service may still be starting — check: journalctl -u pul-registry -n 20"
fi

# ── Summary ───────────────────────────────────────────────────────────────────
echo ""
log "=== M2 · dev-registry setup COMPLETE ==="
MY_IP=$(hostname -I | awk '{print $1}')
info "Registry UI:      http://${MY_IP}:5000/ui/"
info "Catalogue API:    GET http://${MY_IP}:5000/v2/_catalog"
info "Manifest API:     GET http://${MY_IP}:5000/v2/pul/firmware-builder/manifests/latest"
info "Vuln:             Unauthenticated v2 API + MinIO creds in image ENV blob"
info ""
info "Credential seeded: MINIO_ACCESS_KEY=pul-build-svc  MINIO_SECRET_KEY=Artf@ct5tr!PUL24"
info "Next target:       M3 dev-artifacts (11.x.x.x:9000)"
warn "Run Honeytraps/M2-decoy-dev-registry.sh to deploy decoy services"
