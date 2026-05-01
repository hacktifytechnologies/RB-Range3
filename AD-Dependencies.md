# AD Dependencies — RNG-DEV-01 · VIKAS TANTRA
## OPERATION GRIDFALL | v-DMZ Zone

**Note:** RNG-DEV-01 (VIKAS TANTRA) operates in the v-DMZ (`11.0.0.0/8`) zone and does **not** have direct Active Directory dependencies. The machines in this range authenticate via:

- M1 Jenkins: Local service account (no AD auth)
- M2 Container Registry: Service account credentials (no AD auth)
- M3 Artifact Store: MinIO access/secret keys (no AD auth)
- M4 Code Intelligence: SonarQube token-based auth (no AD auth)
- M5 Deploy Commander: API Bearer token (no AD auth)

## Pivot Context
The **exit** from RNG-DEV-01 (M5 dry-run → K8s SA token) leads into:
- **RNG-CLD-01** (`193.x.x.x`) — Kubernetes Cloud Fabric (v-Private zone)
- Kubernetes RBAC governs access — not Windows AD

The subsequent AD engagement happens via:
- RNG-AD-01 (corp.prabalurja.in forest) — reached from the Cloud zone
- Active Directory dependencies documented in RNG-AD-01 exercise materials

## LDAP Cross-Reference
Characters whose LDAP DNs may appear in DEV zone artefacts (commit metadata, config comments):
- `arun.sharma@prabalurja.in` — Jenkins job owner, Docker config author
- `devops@prabalurja.in` — General DevOps team identity used in service configs
- `rajiv.menon@prabalurja.in` — Blue team escalation contact

*RNG-DEV-01 · VIKAS TANTRA | OPERATION GRIDFALL*
