#!/usr/bin/env bash
# M5-decoy-dev-deploy.sh — 7 Honeytrap Decoys
# RNG-DEV-01 VIKAS TANTRA | Deploy Commander Machine
set -euo pipefail
[[ $EUID -ne 0 ]] && { echo "Run as root"; exit 1; }
GREEN='\033[0;32m'; CYAN='\033[0;36m'; NC='\033[0m'
log()  { echo -e "${GREEN}[TRAP]${NC} $*"; }
info() { echo -e "${CYAN}[+]${NC}   $*"; }
D="/opt/pul-decoys/m5"; mkdir -p "$D"

http_decoy() {
  local P=$1 T=$2 M=$3
  python3 -c "
import http.server,socketserver
class H(http.server.BaseHTTPRequestHandler):
    def log_message(self,*a):pass
    def do_GET(self):
        b=b'<html><head><title>$T</title><style>body{font-family:monospace;background:#060a06;color:#39d353;display:flex;align-items:center;justify-content:center;min-height:100vh;margin:0}.w{background:#0d130d;border:1px solid #1a2e1a;padding:36px;border-radius:4px;max-width:480px;text-align:center}h1{color:#56d364;font-size:15px}p{font-size:12px;color:#2ea043}</style></head><body><div class=\"w\"><h1>$T</h1><p>$M</p><p style=\"font-size:10px;color:#1b2d1b;margin-top:16px\">PUL NEXUS-IT DEPLOY COMMANDER</p></div></body></html>'
        self.send_response(200);self.send_header('Content-Type','text/html');self.send_header('Server','PUL-ArgoCD/2.4');self.end_headers();self.wfile.write(b)
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

http_decoy 8889 "PUL ArgoCD Notifications" "Notification webhook — internal cluster use only"
http_decoy 8890 "PUL Helm Repository"      "Internal Helm chart repo — 12 charts"
http_decoy 8891 "PUL GitOps Webhook"       "Push event receiver — git.prabalurja.in"
http_decoy 8892 "PUL Deployment Metrics"   "DORA metrics — internal DevOps reporting"
http_decoy 8893 "PUL Flux CD Operator"     "GitOps operator — cluster: pul-production-k8s"
tcp_decoy  2375 "HTTP/1.1 403 Forbidden\r\nServer: Docker/24.0.7\r\n\r\n{\"message\":\"plaintext disabled, use TLS\"}\r\n"
tcp_decoy  9090 "HTTP/1.1 200 OK\r\nContent-Type: text/plain\r\n\r\n# PUL AlertManager\n# ALERTS: 0 active\n# Endpoint: internal\n"

log "M5 decoys active. Ports: 8889 8890 8891 8892 8893 2375 9090 | Real: 8888"
disown -a 2>/dev/null || true
