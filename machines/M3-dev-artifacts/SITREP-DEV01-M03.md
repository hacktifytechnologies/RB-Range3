# Situation Report (SITREP)
**Report ID:** SITREP-DEV01-M03 | **Incident:** GRIDFALL-RNG-DEV01-M03

---
## 1. Incident Overview
Public-read ACL on `pul-code-reports` S3 bucket allowed unauthenticated download of SonarQube admin credentials. No authentication was required — a plain HTTP GET sufficed.

**Severity:** `HIGH` | **Impact:** Code Intelligence portal credential compromised

---
## 2. Attack Chain
```
[M2 MINIO_ACCESS_KEY] → pul-build-svc:Artf@ct5tr!PUL24
  → GET http://11.x.x.x:9000/pul-code-reports/ (no auth)
  → XML listing → sonar-integration/sonarqube-access.env
  → SONAR_TOKEN=sqa_pul_admin_2024_gridfall
  → PIVOT: M4 dev-sonar (11.x.x.x:9200)
```

---
## 3. Response Actions
- pul-code-reports ACL set to private; all bucket ACLs audited
- SonarQube admin token rotated; all project tokens regenerated
- Bucket policy enforcement implemented — public ACL requires CISO approval

## 4. TTPs
| Tactic | Technique | ID |
|---|---|---|
| Collection | Data from Cloud Storage Object | T1530 |
