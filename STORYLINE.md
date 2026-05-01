# OPERATION GRIDFALL — RNG-DEV-01 Storyline
## Range: VIKAS TANTRA — The Code Forge

---

## Narrative Context

By Day 5 of Operation GRIDFALL, KAAL CHAKRA operator **Rudra-7** — the group's CI/CD and automation specialist — has achieved a persistent foothold on the BGNL DEV zone jump host (`dev-jump.prabalurja.in`). The SSH private key extracted from PUL's Ansible AWX portal has opened the door to Prabal Urja Limited's most sensitive development environment: the **VIKAS TANTRA** code forge.

This is the platform where PUL's DevOps team — under **Arun Sharma**, IT Infrastructure Lead — built the digital transformation stack that was meant to modernise grid operations. In the rush to deliver the NEXUS-IT v2.0 platform by Q3 2024, credential hygiene, access controls, and secret management were systematically deprioritised. The result is a chain of misconfigured development tools that Rudra-7 now exploits with methodical precision.

---

## The VIKAS TANTRA Platform

**VIKAS TANTRA** (Development Engine) is PUL's internal brand for its DevOps CI/CD platform. It consists of:

- **Jenkins CI/CD** — The build orchestration backbone. Manages firmware compilation, integration testing, and deployment pipeline for BGNL grid management software.
- **PUL Container Registry** — Internal Docker registry hosting build agent images, firmware build containers, and deployment tools.
- **PUL Build Artifact Store** — MinIO-compatible S3 object storage for build artefacts, scan reports, and deployment packages.
- **PUL Code Intelligence Portal** — SonarQube-based code quality and security scanning platform. Integrated into every CI pipeline run.
- **PUL Deploy Commander** — GitOps-based deployment orchestrator (ArgoCD-inspired) for Kubernetes workloads. Manages deployments to the v-Private cloud cluster.

---

## Attack Narrative

### Day 5 — DEV Zone Entry
KAAL CHAKRA operator Rudra-7 connects to `dev-jump.prabalurja.in` using the extracted Ed25519 private key. The jump host provides a limited `devops` shell but has outbound access to the internal `11.x.x.x` subnet. A rapid `nmap` sweep reveals five internal service hosts.

> *"Arun Sharma's fingerprints are everywhere in this network,"* Rudra-7 notes in his operational log. *"Jenkins is wide open — no security, no auth. He probably called it 'temporary' twelve months ago."*

### M1 — Jenkins Exploitation
The Jenkins dashboard loads without a login prompt. The build job `pul-firmware-build` has been running automated grid firmware builds since March 2024. Its last successful build artifact, `deploy-bundle.zip`, was archived to allow the deployment team to manually retrieve container credentials without going through the secrets manager — a shortcut introduced during the NEXUS-IT v2.0 crunch period. Rudra-7 downloads it in seconds.

### M2 — Container Registry Enumeration
The Docker registry credential from M1 opens the PUL Container Registry. The `/v2/_catalog` endpoint reveals two repositories. The `pul/firmware-builder` image — the container that compiles BGNL's grid firmware — has its MinIO artifact store credentials baked directly into the image `ENV` layer. This is the legacy of a migration that was never completed: the credentials were supposed to be injected at runtime via Vault, but the image was never rebuilt after the Vault integration was skipped.

### M3 — Artifact Store Breach
The MinIO credentials unlock the PUL Build Artifact Store management interface, but Rudra-7 doesn't even need them for the critical exfiltration. The `pul-code-reports` bucket was misconfigured with `public-read` ACL three months ago by a junior DevOps engineer who forgot to remove the setting after a cross-team code review access issue. It contains a SonarQube integration credential file, sitting unprotected.

### M4 — Code Intelligence Compromise
The SonarQube admin token grants API access to PUL's code scanning platform. A standard API call to `/api/settings/values` for the `pul-firmware-ota` project returns all CI/CD integration settings — including the Deploy Commander API token stored in plain text rather than in the Vault secrets backend. This was supposed to be a temporary configuration. It has been in production for eight months.

### M5 — Deploy Commander Pivot
The Deploy Commander portal controls deployments to PUL's Kubernetes-based cloud fabric. With the API token from M4, Rudra-7 authenticates and triggers a **dry-run sync** of the `pul-ota-firmware` application. The dry-run resolves the full Kubernetes manifest — including a `Secret` object containing a base64-encoded Kubernetes ServiceAccount token for the production cluster at `193.x.x.x:6443`.

> *"RNG-CLD-01 is now reachable,"* Rudra-7 logs at 23:41 IST. *"The cloud fabric is ours. Proceeding to KAAL CHAKRA Phase 3."*

---

## Blue Team Context

**Rajiv Menon** (CISO) has been alerted by the SOC at 23:55 IST on Day 5 — a network scan from the jump host triggered an IDS alert. However, the damage is already done. The blue team must:

1. Identify the attack chain across all five machines
2. Contain the compromised credentials at each stage
3. Remediate the underlying misconfigurations
4. Produce INREP/SITREP documentation for each incident

---

## Network Architecture

```
v-DMZ  11.0.0.0/8
│
├── dev-jump.prabalurja.in  (11.x.x.x)   ← SSH entry from RNG-IT-02 M5
│
├── M1 — jenkins.prabalurja.in  (11.x.x.x:8080)   Jenkins CI/CD
├── M2 — registry.prabalurja.in (11.x.x.x:5000)   Container Registry
├── M3 — artifacts.prabalurja.in (11.x.x.x:9000)  Build Artifact Store
├── M4 — sonar.prabalurja.in    (11.x.x.x:9200)   Code Intelligence
└── M5 — deploy.prabalurja.in   (11.x.x.x:8888)   Deploy Commander
                                                          │
                                              Pivot ──── 193.x.x.x:6443
                                                         (RNG-CLD-01 K8s)
```

---

## Network Zone Reference

| Zone | CIDR | Description |
|---|---|---|
| v-Public | 203.0.0.0/8 | Internet-facing and internal IT systems |
| v-DMZ | 11.0.0.0/8 | Development, CI/CD, and staging systems |
| v-Private | 193.0.0.0/8 | OT-adjacent, SCADA, substation interfaces |

---

*OPERATION GRIDFALL | RNG-DEV-01 · VIKAS TANTRA | Classification: RESTRICTED*
*Prabal Urja Limited NEXUS-IT | © 2026 Hacktify Cybersecurity*
