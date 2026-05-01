# Situation Report (SITREP)
**Report ID:** SITREP-DEV01-M02 | **Incident:** GRIDFALL-RNG-DEV01-M02

---
## 1. Incident Overview
Docker Registry v2 API at `11.x.x.x:5000` unauthenticated — Rudra-7 extracted MinIO credentials from image config blob. The `pul/firmware-builder` image contains MinIO credentials in its `Env` layer from an incomplete Vault migration (DEVOPS-2847 open for 8 months).

**Severity:** `HIGH` | **Impact:** `SIGNIFICANT` — Artifact store credential chain compromised

---
## 2. Attack Chain (This Machine)
```
[M1 docker-config.json] → pul-registry-svc:Rg5try@PUL!Bld24
  → GET /v2/_catalog → enumerate repos
  → GET /v2/pul/firmware-builder/manifests/latest → config digest
  → GET /v2/pul/firmware-builder/blobs/<digest> → Env: MINIO_ACCESS_KEY=pul-build-svc
  → PIVOT: M3 Artifact Store (11.x.x.x:9000)
```

---
## 3. Response Actions
- Registry auth enabled; `pul-build-svc` MinIO credential revoked and rotated
- `pul/firmware-builder` image rebuilt with Vault-sourced credentials at runtime
- DEVOPS-2847 escalated to P1; all images scanned for embedded credential material

## 4. TTPs
| Tactic | Technique | ID |
|---|---|---|
| Discovery | Container and Resource Discovery | T1613 |
| Credential Access | Credentials in Files | T1552.001 |
