#!/usr/bin/env bash
# =============================================================================
# setup.sh — M3 · dev-artifacts · RNG-DEV-01 · VIKAS TANTRA
# Challenge: Public S3 Bucket ACL Misconfiguration + Token in Object
# MITRE: T1530 | Ubuntu 22.04 — NO internet required
# =============================================================================
set -euo pipefail
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; NC='\033[0m'
log()  { echo -e "${GREEN}[SETUP]${NC} $*"; }
info() { echo -e "${CYAN}[INFO]${NC}  $*"; }
warn() { echo -e "${YELLOW}[WARN]${NC}  $*"; }
fail() { echo -e "${RED}[FAIL]${NC}  $*"; exit 1; }
[[ $EUID -ne 0 ]] && fail "Run as root"
python3 -c "import flask" 2>/dev/null || fail "Flask not found — run deps.sh first"

log "=== M3 · dev-artifacts setup starting ==="
APP_DIR="/opt/pul-artifacts"
APP_USER="pul-artifacts"
LOG_DIR="/var/log/pul-artifacts"

id "$APP_USER" &>/dev/null || useradd -r -s /bin/false -d "$APP_DIR" "$APP_USER"
mkdir -p "$APP_DIR/app/templates" "$LOG_DIR"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
log "Installing application files..."
cp -r "$SCRIPT_DIR/app/"* "$APP_DIR/app/"

cat > "$APP_DIR/start.sh" << 'SH'
#!/usr/bin/env bash
cd /opt/pul-artifacts/app
exec python3 app.py
SH
chmod +x "$APP_DIR/start.sh"

cat > /etc/systemd/system/pul-artifacts.service << SVC
[Unit]
Description=PUL Build Artifact Store — NEXUS-IT
After=network.target
[Service]
Type=simple
User=${APP_USER}
WorkingDirectory=${APP_DIR}/app
ExecStart=/usr/bin/python3 ${APP_DIR}/app/app.py
Restart=always
RestartSec=5
SyslogIdentifier=pul-artifacts
[Install]
WantedBy=multi-user.target
SVC

chown -R "$APP_USER:$APP_USER" "$APP_DIR" "$LOG_DIR"
echo "artifacts.prabalurja.in" > /etc/hostname
hostname artifacts.prabalurja.in 2>/dev/null || true

log "Starting pul-artifacts service..."
systemctl daemon-reload
systemctl enable pul-artifacts
systemctl start pul-artifacts
sleep 3

MY_IP=$(hostname -I | awk '{print $1}')
log "=== M3 · dev-artifacts setup COMPLETE ==="
info "Management UI:  http://${MY_IP}:9000/ (requires MinIO creds)"
info "Public bucket:  GET http://${MY_IP}:9000/pul-code-reports/"
info "Target object:  GET http://${MY_IP}:9000/pul-code-reports/sonar-integration/sonarqube-access.env"
info "Vuln:           public-read ACL on pul-code-reports bucket"
info "Credential:     SONAR_TOKEN=sqa_pul_admin_2024_gridfall → M4 (11.x.x.x:9200)"
warn "Run Honeytraps/M3-decoy-dev-artifacts.sh to deploy decoy services"
