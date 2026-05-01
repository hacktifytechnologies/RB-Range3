#!/usr/bin/env bash
# =============================================================================
# setup.sh — M5 · dev-deploy · RNG-DEV-01 · VIKAS TANTRA
# Challenge: Dry-run API Returns Full K8s Manifest with ServiceAccount Token
# MITRE: T1552.001 | Ubuntu 22.04 — NO internet required
# Pivot: 193.x.x.x:6443 → RNG-CLD-01
# =============================================================================
set -euo pipefail
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; NC='\033[0m'
log()  { echo -e "${GREEN}[SETUP]${NC} $*"; }
info() { echo -e "${CYAN}[INFO]${NC}  $*"; }
warn() { echo -e "${YELLOW}[WARN]${NC}  $*"; }
fail() { echo -e "${RED}[FAIL]${NC}  $*"; exit 1; }
[[ $EUID -ne 0 ]] && fail "Run as root"
python3 -c "import flask" 2>/dev/null || fail "Flask not found — run deps.sh first"

log "=== M5 · dev-deploy setup starting ==="
APP_DIR="/opt/pul-deploy"
APP_USER="pul-deploy"
LOG_DIR="/var/log/pul-deploy"

id "$APP_USER" &>/dev/null || useradd -r -s /bin/false -d "$APP_DIR" "$APP_USER"
mkdir -p "$APP_DIR/app/templates" "$LOG_DIR"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
log "Installing application files..."
cp -r "$SCRIPT_DIR/app/"* "$APP_DIR/app/"

cat > "$APP_DIR/start.sh" << 'SH'
#!/usr/bin/env bash
cd /opt/pul-deploy/app
exec python3 app.py
SH
chmod +x "$APP_DIR/start.sh"

cat > /etc/systemd/system/pul-deploy.service << SVC
[Unit]
Description=PUL Deploy Commander — NEXUS-IT
After=network.target
[Service]
Type=simple
User=${APP_USER}
WorkingDirectory=${APP_DIR}/app
ExecStart=/usr/bin/python3 ${APP_DIR}/app/app.py
Restart=always
RestartSec=5
SyslogIdentifier=pul-deploy
[Install]
WantedBy=multi-user.target
SVC

chown -R "$APP_USER:$APP_USER" "$APP_DIR" "$LOG_DIR"
echo "deploy.prabalurja.in" > /etc/hostname
hostname deploy.prabalurja.in 2>/dev/null || true

log "Starting pul-deploy service..."
systemctl daemon-reload
systemctl enable pul-deploy
systemctl start pul-deploy
sleep 3

MY_IP=$(hostname -I | awk '{print $1}')
log "=== M5 · dev-deploy setup COMPLETE ==="
info "Portal UI:       http://${MY_IP}:8888/"
info "API List:        GET http://${MY_IP}:8888/api/applications (Bearer dc-pul-deploy-2024-gridfall)"
info "Dry-run API:     POST http://${MY_IP}:8888/api/applications/pul-ota-firmware/sync?dryRun=true"
info "Vuln:            dryRun=true returns K8s manifest with SA token + 193.x.x.x:6443"
info "PIVOT:           kubectl --kubeconfig extracted → RNG-CLD-01 (193.x.x.x)"
warn "Run Honeytraps/M5-decoy-dev-deploy.sh to deploy decoy services"
