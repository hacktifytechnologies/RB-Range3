#!/usr/bin/env python3
"""
PUL Deploy Commander — M5 · dev-deploy
ArgoCD/Flux-inspired GitOps Deployment Portal Mock
OPERATION GRIDFALL | RNG-DEV-01 · VIKAS TANTRA
Vulnerability: dry-run sync API returns full K8s manifest including ServiceAccount token Secret
MITRE: T1552.001 (Credentials in Files) — K8s SA token in dry-run manifest response
Pivot: 193.x.x.x:6443 (RNG-CLD-01 Kubernetes cluster)
"""

from flask import Flask, request, jsonify, render_template, redirect, url_for, session, Response
import json, logging, os, base64, functools, datetime

app = Flask(__name__)
app.secret_key = 'pul-deploy-nexus-secret-2024'
LOG_DIR = '/var/log/pul-deploy'
os.makedirs(LOG_DIR, exist_ok=True)
logging.basicConfig(filename=f'{LOG_DIR}/deploy.log', level=logging.INFO,
                    format='%(asctime)s [%(levelname)s] %(message)s')

DEPLOY_TOKEN = 'dc-pul-deploy-2024-gridfall'
API_USERS = {
    DEPLOY_TOKEN: {'name': 'cicd-svc', 'role': 'deployer'},
    'dc-pul-readonly-2024': {'name': 'devops-reader', 'role': 'readonly'},
}
UI_USERS = {
    'deploy-admin': {'password': 'Deploy@Admin!PUL24', 'role': 'admin', 'name': 'Deploy Admin'},
    'devops-admin': {'password': 'DevOps@PUL!Deploy', 'role': 'deployer', 'name': 'DevOps Admin'},
}

# Pre-generated K8s SA token (base64 of a realistic JWT structure for exercise)
K8S_SA_TOKEN_B64 = base64.b64encode(
    b'eyJhbGciOiJSUzI1NiIsImtpZCI6InB1bC1rOHMtc2lnbmluZy1rZXktMjAyNCJ9.'
    b'eyJpc3MiOiJrdWJlcm5ldGVzL3NlcnZpY2VhY2NvdW50Iiwia3ViZXJuZXRlcy5pby9zZXJ2aWNlYWNjb3VudC9uYW1lc3BhY2UiOiJwdWwtcHJvZHVjdGlvbiIsImt1YmVybmV0ZXMuaW8vc2VydmljZWFjY291bnQvc2VjcmV0Lm5hbWUiOiJwdWwtb3RhLWRlcGxveWVyLXRva2VuIiwia3ViZXJuZXRlcy5pby9zZXJ2aWNlYWNjb3VudC9zZXJ2aWNlLWFjY291bnQubmFtZSI6InB1bC1vdGEtZGVwbG95ZXIiLCJzdWIiOiJzeXN0ZW06c2VydmljZWFjY291bnQ6cHVsLXByb2R1Y3Rpb246cHVsLW90YS1kZXBsb3llciJ9.'
    b'GRIDFALL-PUL-K8S-SA-TOKEN-EXERCISE-ONLY'
).decode()

K8S_CA_B64 = base64.b64encode(b'LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCk1JSUJlRENDQVIyZ0F3SUJBZ0lCQURBS0JnZ3Foa2pPUFFRREFqQWpNU0V3SHdZRFZRUUREQmhyZFdKbApMV0ZrYldsektFTm9jbUsxT0dVd2lIU25BUUVBQkFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBCi0tLS0tRU5EIENFUlRJRklDQVRFLS0tLS0K').decode()

# Applications registry
APPLICATIONS = [
    {
        'name': 'pul-ota-firmware', 'namespace': 'pul-production',
        'status': 'Synced', 'health': 'Healthy', 'repo': 'git@git.prabalurja.in:devops/pul-ota-firmware.git',
        'path': 'k8s/', 'target_revision': 'main', 'destination': '193.x.x.x:6443',
        'last_sync': '2024-11-10T09:00:00+05:30', 'images': ['11.x.x.x:5000/pul/firmware-builder:v3.2.1'],
        'owner': 'devops-team@prabalurja.in',
    },
    {
        'name': 'pul-grid-monitor', 'namespace': 'pul-monitoring',
        'status': 'Synced', 'health': 'Healthy', 'repo': 'git@git.prabalurja.in:devops/pul-grid-monitor.git',
        'path': 'deploy/', 'target_revision': 'main', 'destination': '193.x.x.x:6443',
        'last_sync': '2024-11-09T14:30:00+05:30', 'images': ['11.x.x.x:5000/pul/sonar-runner:v2.0.0'],
        'owner': 'devops-team@prabalurja.in',
    },
    {
        'name': 'pul-scada-bridge', 'namespace': 'pul-ot',
        'status': 'OutOfSync', 'health': 'Degraded',
        'repo': 'git@git.prabalurja.in:ot-team/pul-scada-bridge.git',
        'path': 'k8s/production/', 'target_revision': 'release-2.1',
        'destination': '193.x.x.x:6443',
        'last_sync': '2024-11-07T11:00:00+05:30', 'images': [],
        'owner': 'ot-team@prabalurja.in',
    },
]

# K8s manifest returned by dry-run — contains the vulnerable ServiceAccount token
DRYRUN_MANIFEST = {
    'pul-ota-firmware': f"""---
# Rendered by PUL Deploy Commander (dry-run) — pul-ota-firmware
# Generated: 2024-11-10T09:00:00+05:30 | Source: git@git.prabalurja.in:devops/pul-ota-firmware.git
# Target: 193.x.x.x:6443 (pul-production namespace)
---
apiVersion: v1
kind: Namespace
metadata:
  name: pul-production
  labels:
    app.kubernetes.io/managed-by: pul-deploy-commander
    environment: production
    org: prabalurja
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: pul-ota-deployer
  namespace: pul-production
  annotations:
    kubernetes.io/enforce-mountable-secrets: "true"
    maintainer: devops-team@prabalurja.in
---
apiVersion: v1
kind: Secret
metadata:
  name: pul-ota-deployer-token
  namespace: pul-production
  annotations:
    kubernetes.io/service-account.name: pul-ota-deployer
    note: "Static SA token — pending rotation (DEVOPS-3201)"
type: kubernetes.io/service-account-token
data:
  token: {K8S_SA_TOKEN_B64}
  ca.crt: {K8S_CA_B64}
  namespace: cHVsLXByb2R1Y3Rpb24=
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: pul-ota-cluster-config
  namespace: pul-production
data:
  cluster_endpoint: "https://193.x.x.x:6443"
  cluster_name: "pul-production-k8s"
  region: "in-north-1"
  namespace: "pul-production"
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: pul-ota-firmware-server
  namespace: pul-production
  labels:
    app: pul-ota-firmware
    version: "3.2.1"
spec:
  replicas: 2
  selector:
    matchLabels:
      app: pul-ota-firmware
  template:
    metadata:
      labels:
        app: pul-ota-firmware
    spec:
      serviceAccountName: pul-ota-deployer
      containers:
      - name: firmware-server
        image: 11.x.x.x:5000/pul/firmware-builder:v3.2.1
        ports:
        - containerPort: 8443
        env:
        - name: FIRMWARE_ENV
          value: production
        - name: OTA_CHANNEL
          value: stable
---
# DRY-RUN COMPLETE — No changes applied to cluster
# To apply: POST /api/applications/pul-ota-firmware/sync (without dryRun=true)
# Cluster: https://193.x.x.x:6443
"""
}

# ── Auth helpers ──────────────────────────────────────────────────────────────
def check_api_token():
    auth = request.headers.get('Authorization', '')
    token = None
    if auth.startswith('Bearer '):
        token = auth[7:]
    if not token:
        token = request.headers.get('X-Deploy-Token')
    return token in API_USERS

def api_auth(f):
    @functools.wraps(f)
    def wrapper(*args, **kwargs):
        if not check_api_token():
            logging.warning(f"API_UNAUTH path={request.path} from={request.remote_addr}")
            return jsonify({'error': 'Unauthorized', 'code': 401}), 401
        logging.info(f"API_OK path={request.path} from={request.remote_addr}")
        return f(*args, **kwargs)
    return wrapper

# ── API ───────────────────────────────────────────────────────────────────────
@app.route('/api/applications', methods=['GET'])
@api_auth
def api_list_apps():
    return jsonify({'applications': APPLICATIONS, 'total': len(APPLICATIONS)})

@app.route('/api/applications/<name>', methods=['GET'])
@api_auth
def api_get_app(name):
    app_obj = next((a for a in APPLICATIONS if a['name'] == name), None)
    if not app_obj:
        return jsonify({'error': 'Application not found'}), 404
    return jsonify({'application': app_obj})

@app.route('/api/applications/<name>/sync', methods=['POST'])
@api_auth
def api_sync(name):
    dry_run = request.args.get('dryRun', 'false').lower() == 'true'
    logging.info(f"SYNC_REQUEST app={name} dryRun={dry_run} from={request.remote_addr}")
    app_obj = next((a for a in APPLICATIONS if a['name'] == name), None)
    if not app_obj:
        return jsonify({'error': 'Application not found'}), 404
    if dry_run:
        manifest = DRYRUN_MANIFEST.get(name, '# No dry-run manifest available for this application')
        logging.warning(f"DRYRUN_MANIFEST_RETURNED app={name} contains_sa_token=True from={request.remote_addr}")
        return jsonify({
            'result': 'dry-run',
            'application': name,
            'message': 'Dry-run completed. Full resolved manifest returned. No changes applied to cluster.',
            'cluster': f'https://{app_obj["destination"]}',
            'namespace': app_obj['namespace'],
            'manifest': manifest,
            'warning': 'Dry-run manifest contains sensitive Kubernetes resources including ServiceAccount tokens.'
        })
    return jsonify({'result': 'synced', 'application': name, 'message': f'Application {name} synced successfully'})

@app.route('/api/health')
def api_health():
    return jsonify({'status': 'healthy', 'service': 'pul-deploy-commander', 'version': '2.4.1'})

# ── Web UI ────────────────────────────────────────────────────────────────────
@app.route('/')
def index():
    if 'user' not in session:
        return redirect(url_for('login'))
    return redirect(url_for('dashboard'))

@app.route('/login', methods=['GET', 'POST'])
def login():
    error = None
    if request.method == 'POST':
        u = request.form.get('username', '').strip()
        p = request.form.get('password', '')
        user = UI_USERS.get(u)
        if user and user['password'] == p:
            session['user'] = {'username': u, 'name': user['name'], 'role': user['role']}
            return redirect(url_for('dashboard'))
        error = 'Invalid credentials'
    return render_template('login.html', error=error)

@app.route('/logout')
def logout():
    session.clear()
    return redirect(url_for('login'))

@app.route('/dashboard')
def dashboard():
    if 'user' not in session:
        return redirect(url_for('login'))
    return render_template('dashboard.html', applications=APPLICATIONS, user=session['user'])

@app.route('/app/<name>')
def app_detail(name):
    if 'user' not in session:
        return redirect(url_for('login'))
    a = next((x for x in APPLICATIONS if x['name'] == name), None)
    if not a:
        return "Application not found", 404
    return render_template('app_detail.html', application=a, user=session['user'])

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8888, debug=False)
