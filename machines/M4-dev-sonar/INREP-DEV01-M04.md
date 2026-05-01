# Incident Notification Report (INREP)
**Classification:** RESTRICTED | **Report ID:** INREP-DEV01-M04
**Incident:** GRIDFALL-RNG-DEV01-M04 | **Addressed To:** Rajiv Menon, CISO

---
## 1. Current Situation
The PUL Code Intelligence Portal (`11.x.x.x:9200`) stores the Deploy Commander API token in plain text as a project configuration setting. Rudra-7, using admin token `sqa_pul_admin_2024_gridfall` from M3, queried `/api/settings/values?component=pul-firmware-ota` and extracted `dc-pul-deploy-2024-gridfall`. The token was placed in project settings as a "temporary" measure while Vault integration was pending (DEVOPS-3102 — open 6 months). Pivot to M5 Deploy Commander is in progress.

**Threat Level:** `CRITICAL`

---
## 2. IOCs
| Type | Value |
|---|---|
| API Endpoint | GET /api/settings/values?component=pul-firmware-ota |
| Token Used | sqa_pul_admin_2024_gridfall (SonarQube admin) |
| Token Extracted | dc-pul-deploy-2024-gridfall (Deploy Commander API) |
| Config Flaw | sonar.ci.deploy_token stored as project setting instead of Vault |

---
## 3. Immediate Actions
1. Revoke sqa_pul_admin_2024_gridfall and dc-pul-deploy-2024-gridfall immediately
2. Remove sonar.ci.deploy_token from all project settings
3. Alert Deploy Commander (M5) team of credential compromise
4. Escalate DEVOPS-3102 Vault integration to P0

**Prepared By:** Blue Team — [Team Name] | **Reference:** GRIDFALL-RNG-DEV01-M04
