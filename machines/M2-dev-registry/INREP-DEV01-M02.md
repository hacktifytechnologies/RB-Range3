# Incident Notification Report (INREP)
**Classification:** RESTRICTED | **Report ID:** INREP-DEV01-M02
**Incident:** GRIDFALL-RNG-DEV01-M02
**Addressed To:** Rajiv Menon, CISO

---
## 1. Current Situation
The PUL Container Registry (`11.x.x.x:5000`) exposes Docker Registry v2 API without authentication. KAAL CHAKRA operator Rudra-7 enumerated repositories via `/v2/_catalog`, retrieved the `pul/firmware-builder:latest` image manifest, and downloaded the config blob. The blob's `Env` array contains plaintext MinIO artifact store credentials (`MINIO_ACCESS_KEY=pul-build-svc`, `MINIO_SECRET_KEY=Artf@ct5tr!PUL24`). These credentials were baked into the image during a failed Vault integration — a known technical debt item (DEVOPS-2847). Pivot to M3 Artifact Store is in progress.

**Threat Level:** `HIGH`

---
## 2. IOCs
| Type | Value |
|---|---|
| API Endpoints Hit | `/v2/_catalog`, `/v2/pul/firmware-builder/manifests/latest`, `/v2/pul/firmware-builder/blobs/<digest>` |
| Credential Exposed | MINIO_ACCESS_KEY=pul-build-svc / MINIO_SECRET_KEY=Artf@ct5tr!PUL24 |
| Root Cause | Credentials in Docker image ENV (DEVOPS-2847 never resolved) |

---
## 3. Immediate Actions
1. Enable registry authentication (htpasswd or token auth)
2. Rotate MinIO `pul-build-svc` credentials immediately
3. Rebuild `pul/firmware-builder` image with Vault-injected credentials
4. Alert M3 artifact store team of credential compromise

**Prepared By:** Blue Team — [Team Name] | **Reference:** GRIDFALL-RNG-DEV01-M02
