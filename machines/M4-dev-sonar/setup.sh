#!/usr/bin/env bash
# =============================================================================
# setup.sh — M4 · dev-sonar · RNG-DEV-01 · VIKAS TANTRA
# Challenge: Plaintext CI/CD Token in SonarQube Settings API Response
# MITRE: T1552.002 | Ubuntu 22.04 — NO internet required
# =============================================================================
set -euo pipefail
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; NC='\033[0m'
log()  { echo -e "${GREEN}[SETUP]${NC} $*"; }
info() { echo -e "${CYAN}[INFO]${NC}  $*"; }
warn() { echo -e "${YELLOW}[WARN]${NC}  $*"; }
fail() { echo -e "${RED}[FAIL]${NC}  $*"; exit 1; }
[[ $EUID -ne 0 ]] && fail "Run as root"
python3 -c "import flask" 2>/dev/null || fail "Flask not found — run deps.sh first"

log "=== M4 · dev-sonar setup starting ==="
APP_DIR="/opt/pul-sonar"
APP_USER="pul-sonar"
LOG_DIR="/var/log/pul-sonar"

id "$APP_USER" &>/dev/null || useradd -r -s /bin/false -d "$APP_DIR" "$APP_USER"
mkdir -p "$APP_DIR/app/templates" "$LOG_DIR"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
log "Installing application files..."
cp -r "$SCRIPT_DIR/app/"* "$APP_DIR/app/"

cat > "$APP_DIR/start.sh" << 'SH'
#!/usr/bin/env bash
cd /opt/pul-sonar/app
exec python3 app.py
SH
chmod +x "$APP_DIR/start.sh"

cat > /etc/systemd/system/pul-sonar.service << SVC
[Unit]
Description=PUL Code Intelligence Portal — NEXUS-IT
After=network.target
[Service]
Type=simple
User=${APP_USER}
WorkingDirectory=${APP_DIR}/app
ExecStart=/usr/bin/python3 ${APP_DIR}/app/app.py
Restart=always
RestartSec=5
SyslogIdentifier=pul-sonar
[Install]
WantedBy=multi-user.target
SVC

chown -R "$APP_USER:$APP_USER" "$APP_DIR" "$LOG_DIR"
echo "sonar.prabalurja.in" > /etc/hostname
hostname sonar.prabalurja.in 2>/dev/null || true

log "Starting pul-sonar service..."
systemctl daemon-reload
systemctl enable pul-sonar
systemctl start pul-sonar
sleep 3

MY_IP=$(hostname -I | awk '{print $1}')
log "=== M4 · dev-sonar setup COMPLETE ==="
info "Portal UI:       http://${MY_IP}:9200/"
info "Admin token:     sqa_pul_admin_2024_gridfall (from M3)"
info "Settings API:    GET http://${MY_IP}:9200/api/settings/values?component=pul-firmware-ota"
info "Vuln:            sonar.ci.deploy_token in plaintext API response"
info "Credential:      dc-pul-deploy-2024-gridfall → M5 (11.x.x.x:8888)"
warn "Run Honeytraps/M4-decoy-dev-sonar.sh to deploy decoy services"
