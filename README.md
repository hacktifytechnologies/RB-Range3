# RNG-DEV-01 
## OPERATION GRIDFALL — DevOps & CI/CD Zone
### Prabal Urja Limited (PUL) — NEXUS-IT Platform

---

**Range:** RNG-DEV-01 · Code Forge
**Zone:** v-DMZ — `11.0.0.0/8` — Subnet: `11.x.x.x/24`
**Entry:** SSH pivot from RNG-IT-02 M5 (dev-jump.prabalurja.in — `11.x.x.x`)
**Pivot To:** RNG-CLD-01 (`193.x.x.x`) via Kubernetes service account token

---

## Machine Manifest

| # | Slug | Service | Port | Vulnerability | Severity |
|---|---|---|---|---|---|
| M1 | dev-jenkins | Jenkins CI/CD 2.x | 8080 | Anonymous read + unauthenticated artifact download | Hard |
| M2 | dev-registry | PUL Container Registry (Docker v2 API) | 5000 | Unauthenticated v2 API + credentials in image ENV blob | Hard |
| M3 | dev-artifacts | PUL Build Artifact Store (S3-compat) | 9000 | Public bucket ACL misconfiguration + token in object | Hard |
| M4 | dev-sonar | PUL Code Intelligence Portal | 9200 | Plaintext CI/CD token in settings API response | Extreme |
| M5 | dev-deploy | PUL Deploy Commander | 8888 | Dry-run API returns full K8s manifest with SA token | Extreme |

---

## Credential Chain

```
[R2-M5 SSH key] → SSH devops@11.x.x.x (dev-jump)
  │
  ├─ Subnet scan: nmap 11.x.x.x/24 → discover M1:8080
  │
  M1 → Jenkins anon API → artifact → docker-config.json
       Credential: pul-registry-svc : Rg5try@PUL!Bld24
  │
  M2 → Registry v2 /v2/_catalog → manifest → config blob
       Credential: MINIO_ACCESS_KEY=pul-build-svc
                   MINIO_SECRET_KEY=Artf@ct5tr!PUL24
  │
  M3 → S3 public bucket → sonarqube-access.env
       Credential: SONAR_TOKEN=sqa_pul_admin_2024_gridfall
                   SONAR_HOST=11.x.x.x:9200
  │
  M4 → SonarQube /api/settings/values → CI integration
       Credential: sonar.ci.deploy_token=dc-pul-deploy-2024-gridfall
  │
  M5 → Deploy Commander dry-run API → K8s manifest
       Pivot: 193.x.x.x:6443 + ServiceAccount token
  │
  RNG-CLD-01 → kubectl --kubeconfig=<extracted> get nodes
```

---

## Setup Instructions

### Prerequisites
Each machine is a standalone Ubuntu 22.04 OpenStack VM. For each machine:

```bash
# Step 1: On the target VM, run deps.sh FIRST (requires internet access)
sudo bash machines/MX-dev-<slug>/deps.sh

# Step 2: After deps.sh completes, run setup.sh (no internet required)
sudo bash machines/MX-dev-<slug>/setup.sh

# Step 3: Deploy honeytrap (run after setup.sh)
sudo bash Honeytraps/MX-decoy-dev-<slug>.sh
```

### TTP YAML (AttackEngine)
Each machine has a corresponding TTP YAML in `ttps/`. These are executed by AttackEngine post-VM-snapshot to perform minimal setup verification actions only — the full challenge setup is handled by `setup.sh`.

### Verification

```bash
# M1 — Jenkins
curl -s http://11.x.x.x:8080/api/json | python3 -m json.tool | head -5

# M2 — Container Registry
curl -s http://11.x.x.x:5000/v2/_catalog

# M3 — Artifact Store
curl -s http://11.x.x.x:9000/pul-code-reports/ | head -20

# M4 — Code Intelligence
curl -s http://11.x.x.x:9200/api/projects/search -H "Authorization: Bearer sqa_pul_admin_2024_gridfall"

# M5 — Deploy Commander
curl -s http://11.x.x.x:8888/api/applications -H "Authorization: Bearer dc-pul-deploy-2024-gridfall"
```

---

## Lockheed Martin Kill Chain Coverage

| Phase | Machine | Evidence |
|---|---|---|
| Reconnaissance | Jump host → M1 | Subnet discovery via nmap from jump shell |
| Weaponisation | M1 | Jenkins API enumeration + artifact analysis |
| Delivery | M2 | Docker Registry v2 API exploitation |
| Exploitation | M3 + M4 | S3 ACL bypass + settings API credential extraction |
| Installation | M4 | Token harvesting for authenticated portal access |
| C2 | M5 | Authenticated API abuse + dry-run manifest extraction |
| Actions on Objectives | M5 → RNG-CLD-01 | K8s kubeconfig exfiltration + cloud pivot |

---

## Key Personas (from PUL Universal Storyline)

| Character | Role | Relevance to This Range |
|---|---|---|
| Arun Sharma | IT Infrastructure Lead | Committed docker-config.json to build artefact; introduced Jenkins misconfiguration during rapid delivery |
| Rudra-7 | KAAL CHAKRA CI/CD Operator | Primary operator for this range |
| Rajiv Menon | CISO | Blue team incident response anchor |

---

*RNG-DEV-01 · VIKAS TANTRA · OPERATION GRIDFALL*
*Classification: RESTRICTED — Exercise Staff Only*
*Prabal Urja Limited NEXUS-IT Platform | © 2026 Hacktify Cybersecurity*
