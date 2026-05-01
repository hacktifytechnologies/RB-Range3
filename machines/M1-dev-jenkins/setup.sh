#!/usr/bin/env bash
# =============================================================================
# setup.sh — M1 · dev-jenkins · RNG-DEV-01 · VIKAS TANTRA
# OPERATION GRIDFALL — Prabal Urja Limited NEXUS-IT
# Challenge: Jenkins Anonymous Read Access + Unauthenticated Artifact Download
# MITRE: T1190 · T1552.001
# Ubuntu 22.04 LTS — NO internet access required

# Step 1 — Create devops user
#sudo useradd -m -s /bin/bash devops

# Step 2 — Set up .ssh directory
#sudo mkdir -p /home/devops/.ssh
#sudo chmod 700 /home/devops/.ssh

# Step 3 — Get the public key FROM M5 VM and paste it below
# On M5 run: cat /etc/pul-gridfall/jump_ed25519.pub
# Then paste the output into this command on Range 3 VM1:
#sudo bash -c 'echo "ssh-ed25519 AAAA...PASTE_FULL_KEY_HERE... devops@dev-jump.prabalurja.in GRIDFALL-2024" > /home/devops/.ssh/authorized_keys'

# Step 4 — Fix permissions
#sudo chmod 600 /home/devops/.ssh/authorized_keys
#sudo chown -R devops:devops /home/devops/.ssh /home/devops

# Step 5 — Enable pubkey auth (uncomment the line in sshd_config)
#sudo sed -i 's/#PubkeyAuthentication yes/PubkeyAuthentication yes/' /etc/ssh/sshd_config
#sudo sed -i 's/#AuthorizedKeysFile/AuthorizedKeysFile/' /etc/ssh/sshd_config
#sudo systemctl reload sshd

# Step 6 — Verify
#sudo cat /home/devops/.ssh/authorized_keys
#id devops
# =============================================================================
set -euo pipefail

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; NC='\033[0m'
log()  { echo -e "${GREEN}[SETUP]${NC} $*"; }
info() { echo -e "${CYAN}[INFO]${NC}  $*"; }
warn() { echo -e "${YELLOW}[WARN]${NC}  $*"; }
fail() { echo -e "${RED}[FAIL]${NC}  $*"; exit 1; }

[[ $EUID -ne 0 ]] && fail "Run as root: sudo bash setup.sh"

command -v java >/dev/null 2>&1 || fail "Java not found — run deps.sh first"
command -v jenkins >/dev/null 2>&1 || fail "Jenkins not found — run deps.sh first"

log "=== M1 · dev-jenkins setup starting ==="
log "Challenge: Jenkins 2.x Anonymous Read Access + Artifact Exposure"
log "OPERATION GRIDFALL | VIKAS TANTRA | RNG-DEV-01"
echo ""

JENKINS_HOME="/var/lib/jenkins"
JENKINS_USER="jenkins"

# ── Stop Jenkins if running ────────────────────────────────────────────────────
log "Stopping Jenkins service..."
systemctl stop jenkins 2>/dev/null || true
sleep 2

# ── JAVA_OPTS — disable setup wizard ─────────────────────────────────────────
log "Configuring Jenkins JVM options..."
mkdir -p /etc/systemd/system/jenkins.service.d
cat > /etc/systemd/system/jenkins.service.d/override.conf << 'SYSTEMD'
[Service]
Environment="JAVA_OPTS=-Djava.awt.headless=true -Djenkins.install.runSetupWizard=false"
SYSTEMD

systemctl daemon-reload

# ── Jenkins home directory ────────────────────────────────────────────────────
log "Preparing Jenkins home..."
mkdir -p "${JENKINS_HOME}"/{init.groovy.d,jobs,workspace,secrets,users}

# ── Marker files to skip setup wizard ────────────────────────────────────────
echo "2.440.3" > "${JENKINS_HOME}/jenkins.install.UpgradeWizard.state"
echo "2.440.3" > "${JENKINS_HOME}/jenkins.install.InstallUtil.lastExecVersion"
touch "${JENKINS_HOME}/.jenkins.install.UpgradeWizard.state"

# ── Main Jenkins config.xml (security DISABLED) ───────────────────────────────
log "Writing Jenkins config.xml with useSecurity=false..."
cat > "${JENKINS_HOME}/config.xml" << 'XML'
<?xml version='1.1' encoding='UTF-8'?>
<hudson>
  <disabledAdministrativeMonitors/>
  <version>2.440.3</version>
  <installStateName>RUNNING</installStateName>
  <numExecutors>2</numExecutors>
  <mode>NORMAL</mode>
  <useSecurity>false</useSecurity>
  <authorizationStrategy class="hudson.security.AuthorizationStrategy$Unsecured"/>
  <securityRealm class="hudson.security.SecurityRealm$None"/>
  <disableRememberMe>false</disableRememberMe>
  <projectNamingStrategy class="jenkins.model.ProjectNamingStrategy$DefaultProjectNamingStrategy"/>
  <workspaceDir>${JENKINS_HOME}/workspace/${ITEM_FULL_NAME}</workspaceDir>
  <buildsDir>${ITEM_ROOTDIR}/builds</buildsDir>
  <markupFormatter class="hudson.markup.EscapedMarkupFormatter"/>
  <jdkInstallations/>
  <viewsTabBar class="hudson.views.DefaultViewsTabBar"/>
  <myViewsTabBar class="hudson.views.MyViewsDefaultViewsTabBar"/>
  <clouds/>
  <scmCheckoutRetryCount>0</scmCheckoutRetryCount>
  <views>
    <hudson.model.AllView>
      <owner class="hudson" reference="../../.."/>
      <name>all</name>
      <filterExecutors>false</filterExecutors>
      <filterQueue>false</filterQueue>
      <properties class="hudson.model.View$PropertyList"/>
    </hudson.model.AllView>
  </views>
  <primaryView>all</primaryView>
  <slaveAgentPort>-1</slaveAgentPort>
  <label>pul-jenkins-master</label>
  <nodeProperties/>
  <globalNodeProperties/>
</hudson>
XML

# ── Groovy init script to enforce no security on startup ──────────────────────
cat > "${JENKINS_HOME}/init.groovy.d/00-disable-security.groovy" << 'GROOVY'
import jenkins.model.*
import hudson.security.*

def instance = Jenkins.get()
instance.setSecurityRealm(SecurityRealm.NO_AUTHENTICATION)
instance.setAuthorizationStrategy(AuthorizationStrategy.UNSECURED)
instance.disableSecurity()
instance.save()
println "[PUL-SETUP] Security disabled — unauthenticated access enabled"
GROOVY

# ── Build job: pul-firmware-build ─────────────────────────────────────────────
log "Creating Jenkins build job: pul-firmware-build..."
JOB_DIR="${JENKINS_HOME}/jobs/pul-firmware-build"
mkdir -p "${JOB_DIR}/builds/1/archive/deploy-bundle"
mkdir -p "${JOB_DIR}/builds/permalinks"

# Job config.xml
cat > "${JOB_DIR}/config.xml" << 'XML'
<?xml version='1.1' encoding='UTF-8'?>
<project>
  <description>PUL NEXUS-IT Firmware Build Pipeline — Compiles and packages grid firmware for OTA deployment. Managed by DevOps team (Arun Sharma). Contact: arun.sharma@prabalurja.in</description>
  <keepDependencies>false</keepDependencies>
  <properties/>
  <scm class="hudson.scm.NullSCM"/>
  <canRoam>true</canRoam>
  <disabled>false</disabled>
  <blockBuildWhenDownstreamBuilding>false</blockBuildWhenDownstreamBuilding>
  <blockBuildWhenUpstreamBuilding>false</blockBuildWhenUpstreamBuilding>
  <triggers/>
  <concurrentBuild>false</concurrentBuild>
  <builders>
    <hudson.tasks.Shell>
      <command>
#!/bin/bash
echo "[pul-firmware-build] Starting firmware build pipeline..."
echo "Environment: production"
echo "Build: #${BUILD_NUMBER}"
echo "Initiated by: arun.sharma@prabalurja.in"
      </command>
    </hudson.tasks.Shell>
  </builders>
  <publishers>
    <hudson.tasks.ArtifactArchiver>
      <artifacts>deploy-bundle/**</artifacts>
      <allowEmptyArchive>false</allowEmptyArchive>
      <onlyIfSuccessful>true</onlyIfSuccessful>
      <fingerprint>false</fingerprint>
      <defaultExcludes>true</defaultExcludes>
      <caseSensitive>true</caseSensitive>
      <followSymlinks>false</followSymlinks>
    </hudson.tasks.ArtifactArchiver>
  </publishers>
  <buildWrappers/>
</project>
XML

# Build #1 metadata
cat > "${JOB_DIR}/builds/1/build.xml" << 'XML'
<?xml version='1.1' encoding='UTF-8'?>
<build>
  <keepLog>false</keepLog>
  <number>1</number>
  <timestamp>1731638400000</timestamp>
  <startTime>1731638400000</startTime>
  <result>SUCCESS</result>
  <duration>47823</duration>
  <charset>UTF-8</charset>
  <builtOn></builtOn>
  <workspace>/var/lib/jenkins/workspace/pul-firmware-build</workspace>
  <culprits/>
  <causes>
    <hudson.model.Cause_-UserIdCause>
      <userId>arun.sharma</userId>
      <userName>Arun Sharma</userName>
    </hudson.model.Cause_-UserIdCause>
  </causes>
</build>
XML

# Build console log (realistic)
cat > "${JOB_DIR}/builds/1/log" << 'LOG'
Started by user Arun Sharma
Running as SYSTEM
Building in workspace /var/lib/jenkins/workspace/pul-firmware-build
[pul-firmware-build] Starting firmware build pipeline...
Environment: production
Build: #1

[pul-firmware-build] Cloning firmware repository...
 > git clone --depth 1 git@git.prabalurja.in:devops/pul-ota-firmware.git . --no-checkout
 > git fetch --tags --force --progress -- origin +refs/heads/*:refs/remotes/origin/*
Checking out Revision a3f79b2 (origin/main)

[pul-firmware-build] Installing build dependencies...
go: downloading github.com/pul/firmware-sdk v1.2.3
go: downloading github.com/pul/grid-protocol v2.1.0

[pul-firmware-build] Compiling firmware package...
GOOS=linux GOARCH=arm64 go build -o firmware.bin ./cmd/firmware/...
Build successful: firmware.bin (14.2 MB)

[pul-firmware-build] Running integration tests...
--- PASS: TestFirmwarePackaging (0.42s)
--- PASS: TestChecksumVerification (0.18s)
--- PASS: TestOTAManifest (0.31s)
PASS

[pul-firmware-build] Packaging deployment bundle...
# Note: docker-config.json copied from /etc/pul/build-config/
# TODO (arun.sharma): Move registry creds to Vault before next release
cp /etc/pul/build-config/docker-config.json deploy-bundle/
cp build-manifest.txt deploy-bundle/
echo "PUL firmware build v3.2.1 — DO NOT DISTRIBUTE" > deploy-bundle/deploy-notes.txt

[pul-firmware-build] Archiving artefacts: deploy-bundle/**
Archiving artefacts

Finished: SUCCESS
LOG

# Build permalinks
cat > "${JOB_DIR}/builds/permalinks" << 'PERMA'
lastCompletedBuild 1
lastFailedBuild -1
lastStableBuild 1
lastSuccessfulBuild 1
lastUnstableBuild -1
lastUnsuccessfulBuild -1
PERMA

# ── THE VULNERABLE ARTEFACT: docker-config.json ───────────────────────────────
log "Planting challenge artefact: docker-config.json..."
cat > "${JOB_DIR}/builds/1/archive/deploy-bundle/docker-config.json" << 'JSON'
{
  "_comment": "PUL Container Registry credentials — DO NOT COMMIT TO VCS",
  "_note": "Temporary: registry creds pending Vault migration (ref: DEVOPS-2847)",
  "_owner": "arun.sharma@prabalurja.in",
  "auths": {
    "11.x.x.x:5000": {
      "username": "pul-registry-svc",
      "password": "Rg5try@PUL!Bld24",
      "auth": "cHVsLXJlZ2lzdHJ5LXN2YzpSZzVyeUBQVUwhQmxkMjQ="
    }
  },
  "registry_info": {
    "endpoint": "11.x.x.x:5000",
    "purpose": "PUL firmware container registry — build agent images",
    "environment": "production",
    "last_rotation": "2024-03-15",
    "managed_by": "devops-team@prabalurja.in"
  }
}
JSON

# Build manifest
cat > "${JOB_DIR}/builds/1/archive/deploy-bundle/build-manifest.txt" << 'TXT'
=============================================================
PUL NEXUS-IT — Firmware Build Manifest
Build: #1 | Date: 2024-11-15 08:00:00 IST
Pipeline: pul-firmware-build
Engineer: Arun Sharma <arun.sharma@prabalurja.in>
=============================================================

Artefacts:
  firmware.bin           sha256:a3f79b2c4d5e6f7a8b9c0d1e2f3a4b5c
  docker-config.json     sha256:b2c3d4e5f6a7b8c9d0e1f2a3b4c5d6e7
  deploy-notes.txt       sha256:c3d4e5f6a7b8c9d0e1f2a3b4c5d6e7f8

Container registry: see docker-config.json for push credentials
OTA deployment: use PUL Deploy Commander at http://11.x.x.x:8888
=============================================================
TXT

cat > "${JOB_DIR}/builds/1/archive/deploy-bundle/deploy-notes.txt" << 'TXT'
PUL firmware build v3.2.1 — DO NOT DISTRIBUTE
Grid management firmware — Prabal Urja Limited NEXUS-IT
For deployment issues contact devops@prabalurja.in
TXT

# Additional decoy jobs
log "Creating decoy Jenkins jobs..."
for job in "pul-unit-tests" "pul-ldap-sync" "pul-k8s-deploy-staging"; do
    mkdir -p "${JENKINS_HOME}/jobs/${job}/builds/1"
    cat > "${JENKINS_HOME}/jobs/${job}/config.xml" << XML
<?xml version='1.1' encoding='UTF-8'?>
<project>
  <description>PUL NEXUS-IT internal job — ${job}</description>
  <keepDependencies>false</keepDependencies>
  <properties/>
  <scm class="hudson.scm.NullSCM"/>
  <canRoam>true</canRoam>
  <disabled>false</disabled>
  <triggers/>
  <concurrentBuild>false</concurrentBuild>
  <builders/>
  <publishers/>
  <buildWrappers/>
</project>
XML
    cat > "${JENKINS_HOME}/jobs/${job}/builds/1/build.xml" << XML
<?xml version='1.1' encoding='UTF-8'?>
<build>
  <number>1</number>
  <result>SUCCESS</result>
  <duration>12400</duration>
</build>
XML
done

# ── Host branding ──────────────────────────────────────────────────────────────
log "Configuring system identity..."
echo "jenkins-ci.prabalurja.in" > /etc/hostname
hostname jenkins-ci.prabalurja.in 2>/dev/null || true

cat >> /etc/hosts << 'HOSTS'
# PUL NEXUS-IT Dev Zone
127.0.0.1  jenkins-ci.prabalurja.in
HOSTS

# ── Ownership ─────────────────────────────────────────────────────────────────
log "Setting file ownership..."
chown -R "${JENKINS_USER}:${JENKINS_USER}" "${JENKINS_HOME}"
chmod -R 755 "${JENKINS_HOME}/jobs"

# ── Enable and start Jenkins ──────────────────────────────────────────────────
log "Enabling and starting Jenkins..."
systemctl enable jenkins
systemctl start jenkins

log "Waiting for Jenkins to initialise (up to 90 seconds)..."
WAIT=0
until curl -sf http://localhost:8080/api/json >/dev/null 2>&1 || [[ $WAIT -ge 90 ]]; do
    sleep 3; WAIT=$((WAIT+3)); echo -n "."
done
echo ""

if curl -sf http://localhost:8080/api/json >/dev/null 2>&1; then
    log "Jenkins is UP and responding"
else
    warn "Jenkins may still be starting — check: systemctl status jenkins"
fi

# ── Banner setup ──────────────────────────────────────────────────────────────
mkdir -p /etc/pul
cat > /etc/pul/challenge-info.txt << 'INFO'
PUL NEXUS-IT — Jenkins CI/CD Challenge (M1)
Challenge: Jenkins Anonymous Read Access + Artifact Exposure
Port: 8080
MITRE: T1190 · T1552.001
Range: RNG-DEV-01 · VIKAS TANTRA · OPERATION GRIDFALL
INFO

# ── Completion summary ────────────────────────────────────────────────────────
echo ""
log "=== M1 · dev-jenkins setup COMPLETE ==="
info "Jenkins UI:       http://$(hostname -I | awk '{print $1}'):8080/"
info "Challenge job:    http://$(hostname -I | awk '{print $1}'):8080/job/pul-firmware-build/"
info "Artefact API:     GET /job/pul-firmware-build/lastSuccessfulBuild/artifact/deploy-bundle/docker-config.json"
info "Vuln:             useSecurity=false — no authentication required"
info ""
info "Credential seeded: pul-registry-svc : Rg5try@PUL!Bld24"
info "Next target:      M2 dev-registry (11.x.x.x:5000)"
echo ""
warn "Run Honeytraps/M1-decoy-dev-jenkins.sh to deploy decoy services"
