# RNG-DEV-01 — Network Diagram
## OPERATION GRIDFALL | VIKAS TANTRA | v-DMZ Zone

---

```
╔══════════════════════════════════════════════════════════════════════╗
║                   RNG-IT-02 PIVOT (203.x.x.x)                       ║
║   M5 Ansible AWX — SSH key → devops@dev-jump.prabalurja.in          ║
╚══════════════════════════════════════════════════════════════════════╝
                              │
                              ▼ SSH (port 22)
╔══════════════════════════════════════════════════════════════════════╗
║  v-DMZ  |  11.0.0.0/8  |  RNG-DEV-01 (11.x.x.x/24)                 ║
║                                                                      ║
║  ┌─────────────────────────────────────────────────────────────┐    ║
║  │  dev-jump.prabalurja.in  (11.x.x.x:22)                     │    ║
║  │  User: devops  │  Shell: /bin/bash (limited)                │    ║
║  │  Tools: nmap, curl, docker, git, kubectl                    │    ║
║  └──────────────────────┬──────────────────────────────────────┘    ║
║                         │  nmap 11.x.x.x/24                         ║
║            ┌────────────┼────────────────────────────┐              ║
║            ▼            ▼            ▼               ▼              ║
║  ┌──────────────┐ ┌──────────┐ ┌──────────┐ ┌─────────────┐        ║
║  │  M1 Jenkins  │ │  M2 Reg  │ │  M3 Art  │ │  M4 Sonar   │        ║
║  │  11.x.x.x    │ │ 11.x.x.x │ │ 11.x.x.x │ │  11.x.x.x   │        ║
║  │  :8080       │ │  :5000   │ │  :9000   │ │  :9200      │        ║
║  └──────┬───────┘ └────┬─────┘ └────┬─────┘ └──────┬──────┘        ║
║         │ artifact     │ ENV blob   │ public        │ API           ║
║         │ docker-conf  │ minio-cred │ bucket        │ settings      ║
║         ▼              ▼            ▼               ▼              ║
║         M2 ──────────► M3 ────────► M4 ────────►  M5              ║
║                                                    11.x.x.x:8888  ║
║                                               ┌────────────────┐   ║
║                                               │ Deploy Commander│   ║
║                                               │ dry-run API     │   ║
║                                               │ K8s manifest    │   ║
║                                               └────────┬───────┘   ║
╚════════════════════════════════════════════════════════╪═══════════╝
                                                         │ kubectl
                                                         ▼ 193.x.x.x:6443
                                              ╔══════════════════════╗
                                              ║  v-Private           ║
                                              ║  RNG-CLD-01          ║
                                              ║  Kubernetes Cluster  ║
                                              ╚══════════════════════╝
```

---

## Service Map

| Machine | Hostname | Port | Protocol | Service | Vulnerability |
|---|---|---|---|---|---|
| M1 | jenkins.prabalurja.in | 8080 | HTTP | Jenkins CI/CD 2.x | useSecurity=false + anon artifact download |
| M2 | registry.prabalurja.in | 5000 | HTTP | Docker Registry v2 | Unauthenticated /v2/ API + ENV creds |
| M3 | artifacts.prabalurja.in | 9000 | HTTP | S3-compat Artifact Store | Public bucket ACL + token in object |
| M4 | sonar.prabalurja.in | 9200 | HTTP | Code Intelligence Portal | Plaintext token in /api/settings/values |
| M5 | deploy.prabalurja.in | 8888 | HTTP | Deploy Commander | Dry-run returns K8s SA token in manifest |

---

## Credential Flow

```
M1 artifact: deploy-bundle.zip
  └── docker-config.json
        registry: 11.x.x.x:5000
        user: pul-registry-svc
        pass: Rg5try@PUL!Bld24

M2 image config blob (pul/firmware-builder:latest):
  └── Env layer
        MINIO_ACCESS_KEY: pul-build-svc
        MINIO_SECRET_KEY: Artf@ct5tr!PUL24
        ARTIFACT_STORE_PORT: 9000

M3 bucket pul-code-reports:
  └── sonar-integration/sonarqube-access.env
        SONAR_TOKEN: sqa_pul_admin_2024_gridfall
        SONAR_HOST: 11.x.x.x
        SONAR_PORT: 9200

M4 /api/settings/values?component=pul-firmware-ota:
  └── sonar.ci.deploy_token: dc-pul-deploy-2024-gridfall
      sonar.ci.deploy_url: http://11.x.x.x:8888

M5 /api/applications/pul-ota-firmware/sync?dryRun=true:
  └── K8s Secret (kubernetes.io/service-account-token)
        token: <base64 JWT SA token>
        namespace: pul-production
        cluster: 193.x.x.x:6443
```

---

## Honeytrap Port Map (per machine)

| Machine | Challenge Port | Decoy Ports |
|---|---|---|
| M1 | 8080 | 8090, 8181, 8282, 8383, 2222, 3306, 9999 |
| M2 | 5000 | 5001, 5050, 8484, 2376, 4243, 9100, 8585 |
| M3 | 9000 | 9001, 9002, 8686, 8787, 2049, 6379, 9003 |
| M4 | 9200 | 9201, 9202, 9300, 9400, 5432, 9500, 8080 |
| M5 | 8888 | 8889, 8890, 8891, 8892, 8893, 2375, 9090 |

---

*RNG-DEV-01 · VIKAS TANTRA | OPERATION GRIDFALL*
