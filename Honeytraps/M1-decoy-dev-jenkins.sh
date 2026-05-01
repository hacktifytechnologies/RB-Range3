#!/usr/bin/env bash
# M1-decoy-dev-jenkins.sh — 7 Honeytrap Decoys
# RNG-DEV-01 VIKAS TANTRA | Jenkins Machine
set -euo pipefail
[[ $EUID -ne 0 ]] && { echo "Run as root"; exit 1; }
GREEN='\033[0;32m'; CYAN='\033[0;36m'; NC='\033[0m'
log()  { echo -e "${GREEN}[TRAP]${NC} $*"; }
info() { echo -e "${CYAN}[+]${NC}   $*"; }
D="/opt/pul-decoys/m1"; mkdir -p "$D"

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

http_decoy 8090 "PUL Jenkins Build Node"  "Jenkins Agent OFFLINE — Node: pul-build-agent-01"
http_decoy 8181 "PUL Build Status"        "Build Status Monitor — Service unavailable"
http_decoy 8282 "PUL Build Metrics API"   "Internal metrics — authentication required"
http_decoy 8383 "PUL Nexus Repository"    "Nexus Repository Manager v3 — starting"
tcp_decoy  2222 "SSH-2.0-OpenSSH_8.9p1\r\nPUL NEXUS-IT Build Server\r\n"
tcp_decoy  3306 "PUL-Jenkins-DB MySQL 8.0.35\r\nAccess denied\r\n"
tcp_decoy  9999 "PUL-JENKINS-REMOTING-V4\r\nNode: pul-build-slave-01\r\n"

log "M1 decoys active. Ports: 8090 8181 8282 8383 2222 3306 9999 | Real: 8080"
disown -a 2>/dev/null || true
