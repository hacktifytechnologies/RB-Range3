# solve_blue.md — M1 · dev-jenkins
## Blue Team Detection & Response Writeup
**Range:** RNG-DEV-01 · VIKAS TANTRA
**Machine:** M1 — Jenkins CI/CD Server
**Vulnerability:** Jenkins Anonymous Read Access + Unauthenticated Build Artifact Download
**MITRE ATT&CK:** T1190 · T1552.001

---

## Detection

### Primary Detection Signal — Jenkins Access Logs
Jenkins logs all HTTP requests to `/var/log/jenkins/jenkins.log` and via the system journal. An unauthenticated client performing API enumeration and artefact download produces a clear signature.

```bash
# Check Jenkins access log for anonymous API enumeration
journalctl -u jenkins --since "1 hour ago" | grep -E "api/json|artifact|deploy-bundle"

# Check for anonymous access (no Authentication header)
grep -E "GET /api/json|GET /job/.*/artifact" /var/log/jenkins/jenkins.log | \
    grep -v "authenticated"
```

**Anomaly Signature:**
- `GET /api/json` with `tree=` parameter from external/jump-host IP
- `GET /job/pul-firmware-build/lastSuccessfulBuild/artifact/` from non-internal source
- Source IP: outside normal developer workstation range

---

### Secondary Detection — Network IDS
```
alert http any any -> 11.x.x.x 8080 (
  msg:"GRIDFALL:Jenkins anonymous API enumeration";
  content:"GET"; http_method;
  content:"/api/json"; http_uri;
  content:!"Authorization"; http_header;
  threshold: type both, track by_src, count 3, seconds 30;
  sid:3000101; rev:1;
)

alert http any any -> 11.x.x.x 8080 (
  msg:"GRIDFALL:Jenkins unauthenticated artifact download";
  content:"GET"; http_method;
  content:"artifact"; http_uri;
  content:!"Authorization"; http_header;
  sid:3000102; rev:1;
)
```

---

## Containment

### Immediate (< 5 minutes)
```bash
# Block source IP at firewall
iptables -I INPUT -s <attacker_ip> -p tcp --dport 8080 -j DROP

# Stop external access to Jenkins (internal only)
iptables -I INPUT ! -s 11.x.x.x/24 -p tcp --dport 8080 -j DROP
```

### Short-term (< 1 hour)

**Enable Jenkins Security (CRITICAL):**
```bash
# Stop Jenkins
systemctl stop jenkins

# Edit config.xml — enable security
sed -i 's/<useSecurity>false<\/useSecurity>/<useSecurity>true<\/useSecurity>/' \
    /var/lib/jenkins/config.xml

# Set proper security realm (LDAP or local matrix auth)
# Add to config.xml after useSecurity=true:
cat >> /var/lib/jenkins/config.xml.patch << 'XML'
  <authorizationStrategy class="hudson.security.GlobalMatrixAuthorizationStrategy">
    <permission>hudson.model.Hudson.Administer:arun.sharma</permission>
  </authorizationStrategy>
  <securityRealm class="hudson.security.HudsonPrivateSecurityRealm">
    <disableSignup>true</disableSignup>
  </securityRealm>
XML

systemctl start jenkins
```

---

## Eradication

```bash
# Rotate the exposed registry credential IMMEDIATELY
# Contact: priya.nair@prabalurja.in (DevOps team)
# Revoke: pul-registry-svc token on 11.x.x.x:5000

# Remove credential from artefact (fix root cause)
# Move to Vault: vault kv put secret/pul/registry/build-svc \
#   username="pul-registry-svc" password="<new-rotated-password>"

# Update Jenkins pipeline to use Vault-injected credentials
# Add to Jenkinsfile:
# withVault(vaultSecrets: [[path: 'secret/pul/registry/build-svc', ...]]) { ... }

# Remove existing artefact with embedded credential
rm -rf /var/lib/jenkins/jobs/pul-firmware-build/builds/1/archive/
```

---

## Remediation (Permanent Fix)

1. **Enable Jenkins security** — `useSecurity=true` with LDAP or matrix auth
2. **Credential rotation** — All credentials in all archived artefacts must be treated as compromised
3. **Vault integration** — All CI/CD credentials must be injected at build time from Vault, never stored in artefacts
4. **Artefact ACL** — Only build executor + admin should download sensitive artefacts
5. **Regular artefact audit** — Weekly scan of build artefact content for credential patterns

---

## IOC Summary

| Type | Value |
|---|---|
| Attack Vector | HTTP GET to Jenkins REST API (unauthenticated) |
| Endpoints Hit | `/api/json`, `/job/pul-firmware-build/lastSuccessfulBuild/artifact/deploy-bundle/docker-config.json` |
| Exposed Credential | `pul-registry-svc : Rg5try@PUL!Bld24` |
| Root Cause | `useSecurity=false` in Jenkins `config.xml` |
| Secondary Root Cause | Credential stored in build artefact (not Vault) |

---

| Item | Value |
|---|---|
| Credential Exposed | `pul-registry-svc:Rg5try@PUL!Bld24` (Docker registry) |
| Data Leaked | Internal registry endpoint + service account credential |
| Config Error | `useSecurity=false` in `/var/lib/jenkins/config.xml` |
| Next Range at Risk | M2 dev-registry (`11.x.x.x:5000`) |

---
*solve_blue.md | M1 dev-jenkins | RNG-DEV-01 · VIKAS TANTRA | OPERATION GRIDFALL*
