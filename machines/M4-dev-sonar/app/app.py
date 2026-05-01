#!/usr/bin/env python3
"""
PUL Code Intelligence Portal — M4 · dev-sonar
SonarQube-Compatible Code Quality Platform Mock
OPERATION GRIDFALL | RNG-DEV-01 · VIKAS TANTRA
Vulnerability: Admin token from M3 → /api/settings/values exposes Deploy Commander API token
MITRE: T1552.002 (Credentials in Registry)
"""

from flask import Flask, request, jsonify, render_template, redirect, url_for, session, Response
import json, hashlib, logging, os, functools

app = Flask(__name__)
app.secret_key = 'pul-sonar-nexus-secret-2024'
LOG_DIR = '/var/log/pul-sonar'
os.makedirs(LOG_DIR, exist_ok=True)
logging.basicConfig(filename=f'{LOG_DIR}/sonar.log', level=logging.INFO,
                    format='%(asctime)s [%(levelname)s] %(message)s')

# Admin token (extracted from M3 artifact store)
ADMIN_TOKEN = 'sqa_pul_admin_2024_gridfall'
UI_USERS = {
    'admin': {'password': 'Admin@PUL!Sonar24', 'token': ADMIN_TOKEN, 'name': 'SonarQube Admin'},
    'devops-ci': {'password': 'Ci@PUL!Sonar24', 'token': 'sqa_pul_cicd_readonly_2024', 'name': 'CI/CD Service'},
}

# ── Auth helpers ──────────────────────────────────────────────────────────────
def check_api_token():
    """Check Bearer or Basic auth (token as username, empty password)"""
    auth = request.headers.get('Authorization', '')
    token = None
    if auth.startswith('Bearer '):
        token = auth[7:]
    elif auth.startswith('Basic '):
        import base64
        try:
            decoded = base64.b64decode(auth[6:]).decode()
            token = decoded.split(':')[0]
        except Exception:
            pass
    if not token:
        token = request.args.get('token')
    if not token:
        token = request.headers.get('X-Sonar-Token')
    return token == ADMIN_TOKEN

def api_auth_required(f):
    @functools.wraps(f)
    def wrapper(*args, **kwargs):
        if not check_api_token():
            logging.warning(f"API_UNAUTH path={request.path} from={request.remote_addr}")
            return jsonify({'errors': [{'msg': 'Unauthorized. Please authenticate.', 'code': 401}]}), 401
        logging.info(f"API_OK path={request.path} from={request.remote_addr}")
        return f(*args, **kwargs)
    return wrapper

# ── Projects & metrics data ───────────────────────────────────────────────────
PROJECTS = [
    {
        'key': 'pul-firmware-ota', 'name': 'PUL OTA Firmware',
        'qualifier': 'TRK', 'visibility': 'private',
        'lastAnalysisDate': '2024-11-10T08:45:00+0530',
        'revision': 'a3f79b2c',
        'measures': {'bugs': 0, 'vulnerabilities': 2, 'code_smells': 14,
                     'coverage': 78.4, 'duplicated_lines_density': 3.2,
                     'ncloc': 12450, 'reliability_rating': 'A',
                     'security_rating': 'B', 'sqale_rating': 'A'},
        'quality_gate': {'status': 'OK', 'conditions': []}
    },
    {
        'key': 'pul-grid-monitor', 'name': 'PUL Grid Monitoring Agent',
        'qualifier': 'TRK', 'visibility': 'private',
        'lastAnalysisDate': '2024-11-08T14:22:00+0530',
        'revision': 'b4e89c3d',
        'measures': {'bugs': 3, 'vulnerabilities': 1, 'code_smells': 27,
                     'coverage': 64.1, 'duplicated_lines_density': 5.8,
                     'ncloc': 8920, 'reliability_rating': 'C',
                     'security_rating': 'B', 'sqale_rating': 'B'},
        'quality_gate': {'status': 'WARN', 'conditions': [{'metric': 'coverage', 'status': 'WARN'}]}
    },
    {
        'key': 'pul-scada-bridge', 'name': 'PUL SCADA Bridge API',
        'qualifier': 'TRK', 'visibility': 'private',
        'lastAnalysisDate': '2024-11-05T10:11:00+0530',
        'revision': 'c5f90d4e',
        'measures': {'bugs': 0, 'vulnerabilities': 0, 'code_smells': 6,
                     'coverage': 91.2, 'duplicated_lines_density': 1.1,
                     'ncloc': 4230, 'reliability_rating': 'A',
                     'security_rating': 'A', 'sqale_rating': 'A'},
        'quality_gate': {'status': 'OK', 'conditions': []}
    },
]

# The vulnerable settings — /api/settings/values?component=pul-firmware-ota
# sonar.ci.deploy_token stored in PLAIN TEXT instead of Vault
PROJECT_SETTINGS = {
    'pul-firmware-ota': {
        'settings': [
            {'key': 'sonar.projectName', 'value': 'PUL OTA Firmware', 'inherited': False},
            {'key': 'sonar.links.ci', 'value': 'http://11.x.x.x:8080/job/pul-firmware-build/', 'inherited': False},
            {'key': 'sonar.ci.server', 'value': 'jenkins', 'inherited': False},
            {'key': 'sonar.ci.deploy_url', 'value': 'http://11.x.x.x:8888', 'inherited': False},
            # THE VULNERABILITY: deploy token stored in plain text project setting
            {'key': 'sonar.ci.deploy_token', 'value': 'dc-pul-deploy-2024-gridfall', 'inherited': False},
            {'key': 'sonar.ci.deploy_environment', 'value': 'production', 'inherited': False},
            {'key': 'sonar.exclusions', 'value': '**/vendor/**,**/test/**', 'inherited': False},
        ]
    },
    'pul-grid-monitor': {
        'settings': [
            {'key': 'sonar.projectName', 'value': 'PUL Grid Monitoring Agent', 'inherited': False},
            {'key': 'sonar.links.ci', 'value': 'http://11.x.x.x:8080/job/pul-grid-monitor/', 'inherited': False},
        ]
    },
}

ISSUES = [
    {'key': 'issue-001', 'rule': 'go:S1128', 'severity': 'MINOR', 'component': 'pul-firmware-ota:cmd/main.go', 'message': 'Remove this unused import.', 'status': 'OPEN', 'type': 'CODE_SMELL'},
    {'key': 'issue-002', 'rule': 'go:S4426', 'severity': 'MAJOR', 'component': 'pul-firmware-ota:pkg/crypto/aes.go', 'message': 'Use a secure random IV for AES encryption.', 'status': 'OPEN', 'type': 'VULNERABILITY'},
    {'key': 'issue-003', 'rule': 'go:S1862', 'severity': 'MINOR', 'component': 'pul-firmware-ota:pkg/ota/validate.go', 'message': 'Duplicate conditions in this conditional chain.', 'status': 'CONFIRMED', 'type': 'BUG'},
]

# ── REST API ──────────────────────────────────────────────────────────────────

@app.route('/api/system/status')
def system_status():
    return jsonify({'id': 'pul-sonar', 'version': '10.3.0.82913', 'status': 'UP'})

@app.route('/api/projects/search')
@api_auth_required
def projects_search():
    return jsonify({'paging': {'pageIndex': 1, 'pageSize': 100, 'total': len(PROJECTS)},
                    'components': PROJECTS})

@app.route('/api/settings/values')
@api_auth_required
def settings_values():
    component = request.args.get('component')
    keys_filter = request.args.get('keys', '')
    logging.info(f"SETTINGS_QUERY component={component} keys={keys_filter} from={request.remote_addr}")
    settings = PROJECT_SETTINGS.get(component, {}).get('settings', [])
    if keys_filter:
        keys = [k.strip() for k in keys_filter.split(',')]
        settings = [s for s in settings if s['key'] in keys]
    return jsonify({'settings': settings})

@app.route('/api/issues/search')
@api_auth_required
def issues_search():
    component = request.args.get('componentKeys', '')
    issues = [i for i in ISSUES if component in i.get('component', '')] if component else ISSUES
    return jsonify({'paging': {'total': len(issues)}, 'issues': issues,
                    'components': [], 'rules': [], 'facets': []})

@app.route('/api/measures/component')
@api_auth_required
def measures_component():
    component = request.args.get('component')
    p = next((x for x in PROJECTS if x['key'] == component), None)
    if not p:
        return jsonify({'errors': [{'msg': 'Component not found'}]}), 404
    m = p['measures']
    return jsonify({'component': {'key': component, 'name': p['name'],
                                   'qualifier': 'TRK', 'measures': [
                                       {'metric': k, 'value': str(v)} for k, v in m.items()
                                   ]}})

@app.route('/api/qualitygates/project_status')
@api_auth_required
def quality_gate():
    project = request.args.get('projectKey')
    p = next((x for x in PROJECTS if x['key'] == project), None)
    if not p:
        return jsonify({'errors': [{'msg': 'Component not found'}]}), 404
    return jsonify({'projectStatus': p['quality_gate']})

@app.route('/api/authentication/validate')
def auth_validate():
    token = request.headers.get('X-Sonar-Token', '') or request.args.get('token', '')
    valid = token == ADMIN_TOKEN or any(u['token'] == token for u in UI_USERS.values())
    return jsonify({'valid': valid})

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
            session['user'] = {'username': u, 'name': user['name'], 'token': user['token']}
            logging.info(f"UI_LOGIN_OK user={u} from={request.remote_addr}")
            return redirect(url_for('dashboard'))
        logging.warning(f"UI_LOGIN_FAIL user={u} from={request.remote_addr}")
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
    return render_template('dashboard.html', projects=PROJECTS, user=session['user'])

@app.route('/project/<key>')
def project_detail(key):
    if 'user' not in session:
        return redirect(url_for('login'))
    p = next((x for x in PROJECTS if x['key'] == key), None)
    if not p:
        return "Project not found", 404
    settings = PROJECT_SETTINGS.get(key, {}).get('settings', [])
    issues = [i for i in ISSUES if key in i.get('component', '')]
    return render_template('project.html', project=p, settings=settings, issues=issues, user=session['user'])

@app.route('/health')
def health():
    return jsonify({'status': 'UP', 'service': 'pul-code-intelligence'}), 200

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=9200, debug=False)
