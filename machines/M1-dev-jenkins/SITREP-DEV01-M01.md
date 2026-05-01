# Situation Report (SITREP)
**Report ID:** SITREP-DEV01-M01 | **Incident:** GRIDFALL-RNG-DEV01-M01
**Classification:** RESTRICTED | **Prepared For:** Rajiv Menon, CISO

---

## 1. Incident Overview

KAAL CHAKRA operator Rudra-7 exploited an unauthenticated Jenkins CI/CD instance (`11.x.x.x:8080`) by querying the REST API anonymously and downloading a build artefact containing Docker registry credentials. The exploit required no tools beyond `curl` and standard HTTP — no vulnerability in Jenkins itself was exploited; the misconfiguration (`useSecurity=false`) is the root cause.

**Severity:** `HIGH` | **Impact:** `SIGNIFICANT` — Registry credential compromised; CI/CD chain at risk

---

## 2. Full Attack Chain (This Machine)

```
[R2-M5 SSH key] → SSH devops@11.x.x.x (jump host)
  → nmap scan 11.x.x.x/24 → discover M1:8080 Jenkins
  → GET /api/json (anonymous) → enumerate pul-firmware-build job
  → GET /job/pul-firmware-build/lastSuccessfulBuild/artifact/deploy-bundle/docker-config.json
  → Extract: pul-registry-svc : Rg5try@PUL!Bld24
  → PIVOT: M2 Container Registry (11.x.x.x:5000)
```

---

## 3. Timeline

| Time | Event |
|---|---|
| T+00:00 | Subnet scan from jump host — Jenkins discovered on port 8080 |
| T+00:02 | Anonymous GET /api/json — job enumeration confirmed unauthenticated |
| T+00:04 | GET /job/pul-firmware-build/lastSuccessfulBuild/artifact/deploy-bundle/docker-config.json — credential extracted |
| T+00:05 | Registry credential verified: `pul-registry-svc:Rg5try@PUL!Bld24` |
| T+00:06 | Pivot to M2 Container Registry initiated |

---

## 4. Response Actions

**Containment:**
- Firewall block on Jenkins port 8080 from all non-authorised source IPs
- `pul-registry-svc` credential suspended pending rotation

**Eradication:**
- Jenkins `useSecurity` set to `true`; matrix auth configured with LDAP integration
- All build artefact archives audited; credential-containing artefacts purged
- Vault integration pipeline ticket raised (DEVOPS-2847 re-opened as critical)

**Recovery:**
- Container registry service account re-keyed with new credential managed by Vault
- Jenkins rebuild pipeline updated — credentials injected at runtime via Vault agent
- All Docker base images rebuilt with Vault-sourced credentials

---

## 5. Lessons Learned

The root cause is an organisational pattern observed across the entire NEXUS-IT estate: Arun Sharma's team introduced `useSecurity=false` as a "temporary" configuration during the v2.0 delivery crunch and it was never reverted. The credential-in-artefact issue is a symptom of the same pattern: Vault was planned but never implemented for the build pipeline. **Delivery pressure consistently overrides security controls at PUL** — this is the systemic issue that KAAL CHAKRA is exploiting.

**Recommendation:** Mandatory pre-production security checklist for all CI/CD configurations. Jenkins security must be a blocking gate in the deployment pipeline.

---

## 6. TTPs Observed

| Tactic | Technique | ID |
|---|---|---|
| Initial Access | Exploit Public-Facing Application | T1190 |
| Credential Access | Unsecured Credentials: Credentials in Files | T1552.001 |
| Discovery | Network Service Discovery | T1046 |

---

*SITREP-DEV01-M01 | RNG-DEV-01 VIKAS TANTRA | OPERATION GRIDFALL*
