#!/usr/bin/env bash
# M2-decoy-dev-registry.sh — 7 Honeytrap Decoys
# RNG-DEV-01 VIKAS TANTRA | Container Registry Machine
set -euo pipefail
[[ $EUID -ne 0 ]] && { echo "Run as root"; exit 1; }
GREEN='\033[0;32m'; CYAN='\033[0;36m'; NC='\033[0m'
log()  { echo -e "${GREEN}[TRAP]${NC} $*"; }
info() { echo -e "${CYAN}[+]${NC}   $*"; }
D="/opt/pul-decoys/m2"; mkdir -p "$D"

http_decoy() {
  local P=$1 T=$2 M=$3
  python3 -c "
import http.server,socketserver
class H(http.server.BaseHTTPRequestHandler):
    def log_message(self,*a):pass
    def do_GET(self):
        b=b'<html><head><title>$T</title><style>body{font-family:monospace;background:#0d1117;color:#8b949e;display:flex;align-items:center;justify-content:center;min-height:100vh;margin:0}.w{background:#161b22;border:1px solid #30363d;padding:36px;border-radius:6px;max-width:480px;text-align:center}h1{color:#c9d1d9;font-size:15px}p{font-size:12px;color:#6e7681}</style></head><body><div class=\"w\"><h1>$T</h1><p>$M</p><p style=\"font-size:10px;color:#484f58;margin-top:16px\">Prabal Urja Limited NEXUS-IT</p></div></body></html>'
        self.send_response(200);self.send_header('Content-Type','text/html');self.send_header('Server','PUL-NEXUS-IT/2.4');self.end_headers();self.wfile.write(b)
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

http_decoy 5001 "PUL Registry Notary"    "Docker Content Trust Notary — signature service"
http_decoy 5050 "PUL Registry Mirror"    "Registry mirror — upstream: registry.prabalurja.in"
http_decoy 8484 "PUL Harbor Registry"    "Harbor Enterprise Container Registry — replica"
http_decoy 9100 "PUL Node Exporter"      "Prometheus metrics endpoint — internal only"
http_decoy 8585 "PUL Portainer"          "Portainer — session expired, login via SSO"
tcp_decoy  2376 "HTTP/1.1 401 Unauthorized\r\nServer: Docker/24.0.7\r\n\r\n{\"message\":\"TLS required\"}\r\n"
tcp_decoy  4243 "HTTP/1.0 403 Forbidden\r\nServer: Docker Remote API\r\n\r\n{\"message\":\"access denied\"}\r\n"

log "M2 decoys active. Ports: 5001 5050 8484 9100 8585 2376 4243 | Real: 5000"
disown -a 2>/dev/null || true
