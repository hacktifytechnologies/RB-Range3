#!/usr/bin/env bash
# M4-decoy-dev-sonar.sh — 7 Honeytrap Decoys
# RNG-DEV-01 VIKAS TANTRA | Code Intelligence Machine
set -euo pipefail
[[ $EUID -ne 0 ]] && { echo "Run as root"; exit 1; }
GREEN='\033[0;32m'; CYAN='\033[0;36m'; NC='\033[0m'
log()  { echo -e "${GREEN}[TRAP]${NC} $*"; }
info() { echo -e "${CYAN}[+]${NC}   $*"; }
D="/opt/pul-decoys/m4"; mkdir -p "$D"

http_decoy() {
  local P=$1 T=$2 M=$3
  python3 -c "
import http.server,socketserver
class H(http.server.BaseHTTPRequestHandler):
    def log_message(self,*a):pass
    def do_GET(self):
        b=b'<html><head><title>$T</title><style>body{font-family:monospace;background:#0d1117;color:#00b4d8;display:flex;align-items:center;justify-content:center;min-height:100vh;margin:0}.w{background:#0d1b2a;border:1px solid #0a3d5c;padding:36px;border-radius:6px;max-width:480px;text-align:center}h1{color:#48cae4;font-size:15px}p{font-size:12px;color:#0077a8}</style></head><body><div class=\"w\"><h1>$T</h1><p>$M</p><p style=\"font-size:10px;color:#023e5e;margin-top:16px\">Prabal Urja Limited NEXUS-IT</p></div></body></html>'
        self.send_response(200);self.send_header('Content-Type','text/html');self.send_header('Server','SonarQube/10.3.0');self.end_headers();self.wfile.write(b)
    def do_POST(self):self.do_GET()
with socketserver.TCPServer(('0.0.0.0',$P),H) as s:s.serve_forever()
" &
  info "HTTP :$P — $T"
}

tcp_decoy() {
  local P=$1; shift; local B="$*"
  while true; do printf "$B" | ncat -l "$P" -q 1 2>/dev/null || true; sleep 1; done &
  info "TCP  :$P"
}

http_decoy 9201 "PUL SonarQube CE Legacy"  "SonarQube CE — legacy, migrated to :9200"
http_decoy 9202 "PUL Code Coverage API"    "Coverage aggregator — token required"
http_decoy 9300 "PUL Elasticsearch"        "Code search index — cluster: pul-sonar-index"
http_decoy 9400 "PUL SAST Dashboard"       "SAST findings dashboard — internal only"
http_decoy 9500 "PUL DevSecOps Portal"     "CI/CD security integration hub"
http_decoy 8080 "PUL Code Review Portal"   "Code review — session expired, login via SSO"
tcp_decoy  5432 "PUL-SonarDB PostgreSQL 14.9\r\nAuthentication required\r\nContact: dba@prabalurja.in\r\n"

log "M4 decoys active. Ports: 9201 9202 9300 9400 9500 8080 5432 | Real: 9200"
disown -a 2>/dev/null || true
