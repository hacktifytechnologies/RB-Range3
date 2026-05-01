#!/usr/bin/env bash
# deps.sh — M4 · dev-sonar · RNG-DEV-01
set -euo pipefail
[[ $EUID -ne 0 ]] && { echo "Run as root"; exit 1; }
export DEBIAN_FRONTEND=noninteractive
apt-get update -qq
apt-get install -y -qq python3 python3-pip netcat-openbsd curl
pip3 install -q flask 2>/dev/null || pip3 install flask
echo "=== deps.sh complete ==="
