# Incident Notification Report (INREP)
**Classification:** RESTRICTED | **Report ID:** INREP-DEV01-M05
**Incident:** GRIDFALL-RNG-DEV01-M05 | **Addressed To:** Rajiv Menon, CISO

---
## 1. Current Situation
The PUL Deploy Commander (`11.x.x.x:8888`) sync API accepts a `dryRun=true` parameter that returns the full resolved Kubernetes manifest — including Secret objects. Rudra-7, using token `dc-pul-deploy-2024-gridfall` from M4, triggered a dry-run on `pul-ota-firmware` and received a manifest containing the `pul-ota-deployer-token` Kubernetes ServiceAccount token and the cluster endpoint `193.x.x.x:6443`. This is the pivot credential for RNG-CLD-01.

**CRITICAL — K8s cluster access is IMMINENT. Containment required immediately.**

**Threat Level:** `CRITICAL`

---
## 2. IOCs
| Type | Value |
|---|---|
| API Call | POST /api/applications/pul-ota-firmware/sync?dryRun=true |
| Token Used | dc-pul-deploy-2024-gridfall |
| K8s SA Token | pul-ota-deployer-token (pul-production namespace) |
| Cluster Exposed | 193.x.x.x:6443 |

---
## 3. Immediate Actions
1. ROTATE pul-ota-deployer ServiceAccount token on 193.x.x.x cluster immediately
2. Revoke dc-pul-deploy-2024-gridfall Deploy Commander token
3. Block all traffic from compromised jump host to 193.x.x.x:6443
4. Declare CRITICAL incident — RNG-DEV-01 fully compromised, RNG-CLD-01 at imminent risk
5. Notify K8s cluster admin and network ops for firewall block

**Prepared By:** Blue Team — [Team Name] | **Reference:** GRIDFALL-RNG-DEV01-M05
