#!/usr/bin/env bash
# =============================================================================
# deps.sh — M1 · dev-jenkins · RNG-DEV-01 · VIKAS TANTRA
# Dependencies installer — run ONCE before setup.sh
# Requires internet access | Ubuntu 22.04 LTS

# 1. Install Java 21
#sudo apt-get install -y openjdk-21-jdk-headless

# 2. Set Java 21 as default
#sudo update-alternatives --set java \
#    /usr/lib/jvm/java-21-openjdk-amd64/bin/java

# 3. Confirm
#java -version
# Must show: openjdk version "21..."

# 4. Restart Jenkins
#sudo systemctl restart jenkins
#sudo systemctl status jenkins
# =============================================================================
set -euo pipefail
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'
log()  { echo -e "${GREEN}[DEPS]${NC} $*"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $*"; }
fail() { echo -e "${RED}[FAIL]${NC} $*"; exit 1; }

[[ $EUID -ne 0 ]] && fail "Run as root: sudo bash deps.sh"

log "=== M1 dev-jenkins deps.sh starting ==="
log "Ubuntu 22.04 LTS | Jenkins CI/CD Challenge"

export DEBIAN_FRONTEND=noninteractive

# ── System update ─────────────────────────────────────────────────────────────
log "Updating package index..."
apt-get update -qq

# ── Java (required by Jenkins) ────────────────────────────────────────────────
log "Installing OpenJDK 21 (required by Jenkins 2.440+)..."
apt-get install -y -qq openjdk-21-jdk-headless
update-alternatives --set java /usr/lib/jvm/java-21-openjdk-amd64/bin/java 2>/dev/null || true
java -version 2>&1 | head -1 && log "Java OK"

# ── Utilities needed for key import ───────────────────────────────────────────
log "Installing utilities..."
apt-get install -y -qq curl gnupg2 apt-transport-https ca-certificates \
    ncat netcat-openbsd python3 python3-pip zip unzip jq wget

# ── Jenkins APT repository ────────────────────────────────────────────────────
log "Adding Jenkins APT repository..."

# Clean any previous failed attempt
rm -f /usr/share/keyrings/jenkins-keyring.gpg
rm -f /etc/apt/sources.list.d/jenkins.list

# The jenkins.io-2023.key is expired — use trusted=yes for lab environment
# This is intentional for an exercise range (not production)
log "Configuring Jenkins repo (trusted mode — expired upstream GPG key workaround)..."
echo "deb [trusted=yes] https://pkg.jenkins.io/debian-stable binary/" \
    | tee /etc/apt/sources.list.d/jenkins.list > /dev/null

apt-get update -qq || {
    warn "Jenkins repo update failed — trying direct .deb download fallback..."
    _JENKINS_DIRECT=1
}

# ── Install Jenkins ───────────────────────────────────────────────────────────
log "Installing Jenkins..."

if apt-get install -y -qq jenkins 2>/dev/null; then
    log "Jenkins installed via APT"
else
    # Fallback: download .deb directly
    warn "APT install failed — downloading Jenkins .deb directly..."
    JENKINS_VER="2.440.3"
    JENKINS_DEB="/tmp/jenkins_${JENKINS_VER}_all.deb"
    curl -fsSL -o "$JENKINS_DEB" \
        "https://get.jenkins.io/debian-stable/jenkins_${JENKINS_VER}_all.deb" || \
    curl -fsSL -o "$JENKINS_DEB" \
        "https://mirrors.jenkins.io/debian-stable/jenkins_${JENKINS_VER}_all.deb"
    dpkg -i "$JENKINS_DEB" 2>/dev/null || true
    apt-get install -f -y -qq   # fix deps
    log "Jenkins installed via direct .deb"
fi

# Stop Jenkins before we configure it (setup.sh will start it correctly)
systemctl stop jenkins  2>/dev/null || true
systemctl disable jenkins 2>/dev/null || true

# ── Python for honeytraps ──────────────────────────────────────────────────────
pip3 install -q flask 2>/dev/null || true

# ── Verify ────────────────────────────────────────────────────────────────────
command -v jenkins >/dev/null 2>&1 && log "Jenkins binary: OK" || \
    warn "jenkins binary not in PATH — check: dpkg -l jenkins"

log "=== deps.sh complete — run setup.sh next (no internet required) ==="
