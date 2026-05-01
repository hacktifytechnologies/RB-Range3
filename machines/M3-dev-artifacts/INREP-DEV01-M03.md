# Incident Notification Report (INREP)
**Classification:** RESTRICTED | **Report ID:** INREP-DEV01-M03
**Incident:** GRIDFALL-RNG-DEV01-M03 | **Addressed To:** Rajiv Menon, CISO

---
## 1. Current Situation
The PUL Build Artifact Store (`11.x.x.x:9000`) has the `pul-code-reports` bucket misconfigured with public-read ACL. Rudra-7 accessed the bucket without credentials and downloaded `sonar-integration/sonarqube-access.env`, which contains the SonarQube admin token (`sqa_pul_admin_2024_gridfall`). The ACL was set by a junior DevOps engineer in August 2024 as a temporary cross-team access measure and was never reverted. Pivot to M4 Code Intelligence Portal is in progress.

**Threat Level:** `HIGH`

---
## 2. IOCs
| Type | Value |
|---|---|
| Bucket | pul-code-reports (public-read ACL) |
| Object | sonar-integration/sonarqube-access.env |
| Token Exposed | sqa_pul_admin_2024_gridfall |

---
## 3. Immediate Actions
1. Set `pul-code-reports` ACL to private immediately
2. Rotate SonarQube admin token — token sqa_pul_admin_2024_gridfall is compromised
3. Remove credential files from all S3 buckets — secrets must not be stored as objects
4. Notify Code Intelligence team of impending pivot

**Prepared By:** Blue Team — [Team Name] | **Reference:** GRIDFALL-RNG-DEV01-M03
