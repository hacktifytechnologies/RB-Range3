#!/usr/bin/env bash
# M3-decoy-dev-artifacts.sh — 7 Honeytrap Decoys
# RNG-DEV-01 VIKAS TANTRA | Artifact Store Machine
set -euo pipefail
[[ $EUID -ne 0 ]] && { echo "Run as root"; exit 1; }
GREEN='\033[0;32m'; CYAN='\033[0;36m'; NC='\033[0m'
log()  { echo -e "${GREEN}[TRAP]${NC} $*"; }
info() { echo -e "${CYAN}[+]${NC}   $*"; }
D="/opt/pul-decoys/m3"; mkdir -p "$D"

http_decoy() {
  local P=$1 T=$2 M=$3
  python3 -c "
import http.server,socketserver
class H(http.server.BaseHTTPRequestHandler):
    def log_message(self,*a):pass
    def do_GET(self):
        b=b'<html><head><title>$T</title><style>body{font-family:monospace;background:#0f1e2e;color:#7db9d4;display:flex;align-items:center;justify-content:center;min-height:100vh;margin:0}.w{background:#172232;border:1px solid #1f3a52;padding:36px;border-radius:6px;max-width:480px;text-align:center}h1{color:#a8d4ed;font-size:15px}p{font-size:12px;color:#4a7a94}</style></head><body><div class=\"w\"><h1>$T</h1><p>$M</p><p style=\"font-size:10px;color:#2a4a5e;margin-top:16px\">Prabal Urja Limited NEXUS-IT</p></div></body></html>'
        self.send_response(200);self.send_header('Content-Type','text/html');self.send_header('Server','PUL-MinIO/RELEASE.2024');self.end_headers();self.wfile.write(b)
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

http_decoy 9001 "PUL MinIO Console"      "MinIO Management Console — metrics-only endpoint"
http_decoy 9002 "PUL S3 API v2 Legacy"   "S3-compatible v2 endpoint — use port 9000"
http_decoy 9003 "PUL Build Cache"        "Distributed build cache — internal CI/CD only"
http_decoy 8686 "PUL Artifact Dashboard" "Artefact analytics — VPN required"
http_decoy 8787 "PUL Storage Monitor"    "Storage: 68% used | 4821 objects | 7 buckets"
tcp_decoy  2049 "PUL-NFS-Storage v4\r\nMount: /mnt/pul-artifacts\r\nUnauthorised access prohibited\r\n"
tcp_decoy  6379 "+PONG\r\n-ERR NOAUTH Authentication required (PUL-Redis-Cache)\r\n"

log "M3 decoys active. Ports: 9001 9002 9003 8686 8787 2049 6379 | Real: 9000"
disown -a 2>/dev/null || true
