#!/usr/bin/env bash
# =============================================================================
# deps.sh — M1 · dev-jenkins · RNG-DEV-01 · VIKAS TANTRA
# Dependencies installer — run ONCE before setup.sh
# Requires internet access | Ubuntu 22.04 LTS
# =============================================================================
set -euo pipefail

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'
log()  { echo -e "${GREEN}[DEPS]${NC} $*"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $*"; }
fail() { echo -e "${RED}[FAIL]${NC} $*"; exit 1; }

[[ $EUID -ne 0 ]] && fail "Run as root: sudo bash deps.sh"

log "=== M1 dev-jenkins deps.sh starting ==="
log "Ubuntu 22.04 LTS | Jenkins CI/CD Challenge"

# ── System update ─────────────────────────────────────────────────────────────
log "Updating package index..."
export DEBIAN_FRONTEND=noninteractive
apt-get update -qq

# ── Java (required by Jenkins) ────────────────────────────────────────────────
log "Installing OpenJDK 17..."
apt-get install -y -qq openjdk-17-jdk-headless

java -version 2>&1 | head -1 && log "Java OK"

# ── Jenkins APT repository ────────────────────────────────────────────────────
log "Adding Jenkins APT repository..."
apt-get install -y -qq curl gnupg2 apt-transport-https ca-certificates

curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key \
    | gpg --dearmor -o /usr/share/keyrings/jenkins-keyring.gpg 2>/dev/null

echo "deb [signed-by=/usr/share/keyrings/jenkins-keyring.gpg] \
https://pkg.jenkins.io/debian-stable binary/" \
    | tee /etc/apt/sources.list.d/jenkins.list > /dev/null

apt-get update -qq

# ── Jenkins ───────────────────────────────────────────────────────────────────
log "Installing Jenkins..."
apt-get install -y -qq jenkins

# Prevent Jenkins from starting before we configure it
systemctl stop jenkins 2>/dev/null || true
systemctl disable jenkins 2>/dev/null || true

# ── Utility packages ──────────────────────────────────────────────────────────
log "Installing utilities..."
apt-get install -y -qq \
    ncat netcat-openbsd python3 python3-pip \
    zip unzip jq curl wget

# Python for honeytraps
pip3 install -q flask 2>/dev/null || true

log "=== deps.sh complete — run setup.sh next (no internet required) ==="
