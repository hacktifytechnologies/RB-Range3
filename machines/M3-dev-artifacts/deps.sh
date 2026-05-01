#!/usr/bin/env bash
# deps.sh — M3 · dev-artifacts · RNG-DEV-01
set -euo pipefail
[[ $EUID -ne 0 ]] && { echo "Run as root"; exit 1; }
export DEBIAN_FRONTEND=noninteractive
apt-get update -qq
apt-get install -y -qq python3 python3-pip python3-venv curl netcat-openbsd
pip3 install -q flask 2>/dev/null || pip3 install flask
echo "=== deps.sh complete ==="
