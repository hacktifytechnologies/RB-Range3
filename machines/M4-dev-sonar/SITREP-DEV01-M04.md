# Situation Report (SITREP)
**Report ID:** SITREP-DEV01-M04 | **Incident:** GRIDFALL-RNG-DEV01-M04

---
## 1. Incident Overview
SonarQube project settings API exposed Deploy Commander API token in plaintext. Token extracted via standard API call with admin auth from M3. The settings API is designed to return config — the mistake was storing a secret there.

**Severity:** `CRITICAL` | **Impact:** Deploy Commander credential compromised; K8s cluster access at risk

---
## 2. Attack Chain
```
[M3 SONAR_TOKEN] → sqa_pul_admin_2024_gridfall
  → GET /api/settings/values?component=pul-firmware-ota
  → sonar.ci.deploy_token = dc-pul-deploy-2024-gridfall
  → PIVOT: M5 Deploy Commander (11.x.x.x:8888)
```

---
## 3. Response
- All project tokens and deploy tokens rotated
- sonar.ci.deploy_token removed from all projects; Vault integration DEVOPS-3102 → P0
- Access to Deploy Commander port 8888 restricted; incident declared at CRITICAL level

## 4. TTPs
| Tactic | Technique | ID |
|---|---|---|
| Credential Access | Credentials in Registry | T1552.002 |
