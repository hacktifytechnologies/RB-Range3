# Incident Notification Report (INREP)
**Classification:** RESTRICTED — Internal Use Only
**Report ID:** INREP-DEV01-M01
**Incident:** GRIDFALL-RNG-DEV01-M01
**Prepared By:** SOC Analyst — [Team Name]
**Addressed To:** Rajiv Menon, CISO — rajiv.menon@prabalurja.in

---

## 1. Current Situation

The PUL Jenkins CI/CD server (`11.x.x.x:8080`) is configured with authentication entirely disabled (`useSecurity=false`). KAAL CHAKRA operator **Rudra-7**, having pivoted to the DEV zone jump host from RNG-IT-02, performed an unauthenticated enumeration of the Jenkins REST API and downloaded the archived build artefact from the `pul-firmware-build` job. The artefact contained `docker-config.json` with plaintext credentials for the PUL Container Registry (`pul-registry-svc:Rg5try@PUL!Bld24`). Pivot to M2 is in progress.

**Threat Level:** `HIGH`

---

## 2. IOCs

| Type | Value |
|---|---|
| Attack Source | Jump host `11.x.x.x` (devops user) |
| Target | `11.x.x.x:8080` Jenkins |
| API Endpoints Hit | `/api/json`, `/job/pul-firmware-build/lastSuccessfulBuild/artifact/deploy-bundle/docker-config.json` |
| Credential Exposed | `pul-registry-svc:Rg5try@PUL!Bld24` |
| Config Flaw | `useSecurity=false` in Jenkins `config.xml` |

---

## 3. Vulnerabilities

- **Jenkins no-auth mode:** `useSecurity=false` in `config.xml` disables all access controls. Any HTTP client can enumerate jobs, view console output, and download artefacts.
- **Credential in artefact:** `docker-config.json` with registry credentials was stored as a build artefact — visible to anyone with API access. Arun Sharma's TODO note ("Move registry creds to Vault before next release") indicates this was a known risk that was never addressed.

---

## 4. Immediate Actions Required

1. **Stop Jenkins** and enable authentication immediately
2. **Rotate** `pul-registry-svc` credential on the container registry
3. **Audit** all archived build artefacts for embedded credentials
4. **Notify** Priya Nair (IT Ops) — DevOps team credential hygiene review required
5. **Block** jump host IP from reaching Jenkins port 8080

---

## POC

> **[Attach: curl output showing unauthenticated API response and artefact download]**
> **[Attach: Jenkins access log showing enumeration requests without Authorization header]**

**Prepared By:** Blue Team — [Team Name] | **Reference:** GRIDFALL-RNG-DEV01-M01
