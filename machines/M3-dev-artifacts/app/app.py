#!/usr/bin/env python3
"""
PUL Build Artifact Store — M3 · dev-artifacts
MinIO S3-Compatible Object Storage Mock
OPERATION GRIDFALL | RNG-DEV-01 · VIKAS TANTRA
Vulnerability: Public bucket ACL misconfiguration — pul-code-reports bucket readable without auth
MITRE: T1530 (Data from Cloud Storage Object)
"""

from flask import Flask, request, jsonify, render_template, redirect, url_for, session, Response, make_response
import json, hashlib, logging, os, datetime, xml.etree.ElementTree as ET

app = Flask(__name__)
app.secret_key = 'pul-artifacts-nexus-secret-2024'
LOG_DIR = '/var/log/pul-artifacts'
os.makedirs(LOG_DIR, exist_ok=True)
logging.basicConfig(
    filename=f'{LOG_DIR}/artifacts.log', level=logging.INFO,
    format='%(asctime)s [%(levelname)s] %(message)s'
)

USERS = {
    'pul-build-svc': {'password': 'Artf@ct5tr!PUL24', 'role': 'readwrite', 'name': 'Build Service Account'},
    'pul-admin':     {'password': 'Adm1n@Art!PUL24',  'role': 'admin',     'name': 'Admin'},
    'devops-svc':    {'password': 'DevOps@Svc!24',     'role': 'readonly',  'name': 'DevOps Service'},
}

# ── Bucket definitions ─────────────────────────────────────────────────────────
# pul-code-reports: PUBLIC (misconfigured ACL) — the vulnerable bucket
# others: PRIVATE (require auth)

BUCKETS = {
    'pul-firmware-releases': {
        'public': False,
        'created': '2024-01-10T09:00:00Z',
        'objects': {
            'firmware-v3.2.1.bin': {'size': 14848123, 'content_type': 'application/octet-stream', 'data': 'BINARY_FIRMWARE_DATA', 'last_modified': '2024-11-10'},
            'firmware-v3.1.0.bin': {'size': 14312044, 'content_type': 'application/octet-stream', 'data': 'BINARY_FIRMWARE_DATA', 'last_modified': '2024-10-05'},
            'checksums.sha256': {'size': 256, 'content_type': 'text/plain', 'data': 'a3f79b2c  firmware-v3.2.1.bin\nb5e4d3c2  firmware-v3.1.0.bin\n', 'last_modified': '2024-11-10'},
        }
    },
    'pul-build-cache': {
        'public': False,
        'created': '2024-02-15T11:00:00Z',
        'objects': {
            'go-modules-cache.tar.gz': {'size': 89234567, 'content_type': 'application/gzip', 'data': 'BINARY_CACHE_DATA', 'last_modified': '2024-11-01'},
        }
    },
    'pul-code-reports': {
        'public': True,   # VULNERABILITY: public-read ACL misconfiguration
        'created': '2024-03-20T14:00:00Z',
        'objects': {
            'sonar-integration/sonarqube-access.env': {
                'size': 142,
                'content_type': 'text/plain',
                'last_modified': '2024-11-08',
                'data': (
                    "# PUL SonarQube Integration Credentials\n"
                    "# Auto-generated: 2024-11-08 | devops-automation@prabalurja.in\n"
                    "SONAR_TOKEN=sqa_pul_admin_2024_gridfall\n"
                    "SONAR_HOST=11.x.x.x\n"
                    "SONAR_PORT=9200\n"
                    "SONAR_PROJECT_KEY=pul-firmware-ota\n"
                )
            },
            'build-reports/firmware-scan-2024-11.json': {
                'size': 4892,
                'content_type': 'application/json',
                'last_modified': '2024-11-10',
                'data': json.dumps({
                    "report": "PUL Firmware Static Analysis",
                    "project": "pul-firmware-ota",
                    "date": "2024-11-10",
                    "quality_gate": "PASSED",
                    "metrics": {"bugs": 0, "vulnerabilities": 2, "code_smells": 14, "coverage": 78.4},
                    "note": "Full details: see SonarQube portal at 11.x.x.x:9200"
                }, indent=2)
            },
            'deploy-configs/README.txt': {
                'size': 198,
                'content_type': 'text/plain',
                'last_modified': '2024-09-01',
                'data': (
                    "PUL Code Reports Bucket\n"
                    "=======================\n"
                    "Contains automated CI/CD scan reports and integration configs.\n"
                    "Access: contact devops@prabalurja.in\n"
                    "ACL: Public-read (set 2024-08-15 — review pending)\n"
                )
            },
        }
    },
    'pul-deploy-configs': {
        'public': False,
        'created': '2024-04-01T10:00:00Z',
        'objects': {
            'k8s/namespace-config.yaml': {'size': 512, 'content_type': 'text/yaml', 'data': 'apiVersion: v1\nkind: Namespace\nmetadata:\n  name: pul-production\n', 'last_modified': '2024-11-01'},
        }
    },
}

def s3_xml_response(xml_str, status=200):
    r = make_response(xml_str, status)
    r.headers['Content-Type'] = 'application/xml'
    return r

def bucket_listing_xml(bucket_name, objects):
    root = ET.Element('ListBucketResult')
    root.set('xmlns', 'http://s3.amazonaws.com/doc/2006-03-01/')
    ET.SubElement(root, 'Name').text = bucket_name
    ET.SubElement(root, 'Prefix').text = ''
    ET.SubElement(root, 'MaxKeys').text = '1000'
    ET.SubElement(root, 'IsTruncated').text = 'false'
    for key, obj in objects.items():
        contents = ET.SubElement(root, 'Contents')
        ET.SubElement(contents, 'Key').text = key
        ET.SubElement(contents, 'LastModified').text = obj['last_modified'] + 'T00:00:00.000Z'
        ET.SubElement(contents, 'Size').text = str(obj['size'])
        ET.SubElement(contents, 'StorageClass').text = 'STANDARD'
    return '<?xml version="1.0" encoding="UTF-8"?>' + ET.tostring(root, encoding='unicode')

# ── S3-compatible API ─────────────────────────────────────────────────────────

@app.route('/<bucket>/', methods=['GET'])
@app.route('/<bucket>', methods=['GET'])
def bucket_access(bucket):
    b = BUCKETS.get(bucket)
    if not b:
        return s3_xml_response('<Error><Code>NoSuchBucket</Code><Message>The specified bucket does not exist</Message></Error>', 404)
    if not b['public']:
        auth = request.headers.get('Authorization', '')
        if not auth:
            logging.warning(f"UNAUTH_BUCKET_ACCESS bucket={bucket} from={request.remote_addr}")
            return s3_xml_response('<Error><Code>AccessDenied</Code><Message>Access Denied</Message></Error>', 403)
    logging.info(f"BUCKET_LIST bucket={bucket} from={request.remote_addr} public={b['public']}")
    return s3_xml_response(bucket_listing_xml(bucket, b['objects']))

@app.route('/<bucket>/<path:key>', methods=['GET'])
def object_get(bucket, key):
    b = BUCKETS.get(bucket)
    if not b:
        return s3_xml_response('<Error><Code>NoSuchBucket</Code></Error>', 404)
    if not b['public']:
        auth = request.headers.get('Authorization', '')
        if not auth:
            return s3_xml_response('<Error><Code>AccessDenied</Code><Message>Access Denied</Message></Error>', 403)
    obj = b['objects'].get(key)
    if not obj:
        return s3_xml_response('<Error><Code>NoSuchKey</Code><Message>The specified key does not exist</Message></Error>', 404)
    logging.info(f"OBJECT_GET bucket={bucket} key={key} from={request.remote_addr}")
    return Response(obj['data'], content_type=obj.get('content_type', 'text/plain'))

# ── Management UI ─────────────────────────────────────────────────────────────

@app.route('/')
def index():
    if 'user' not in session:
        return redirect(url_for('login'))
    return redirect(url_for('dashboard'))

@app.route('/login', methods=['GET', 'POST'])
def login():
    error = None
    if request.method == 'POST':
        user = request.form.get('username', '').strip()
        pwd  = request.form.get('password', '')
        u = USERS.get(user)
        if u and u['password'] == pwd:
            session['user'] = {'username': user, 'role': u['role'], 'name': u['name']}
            logging.info(f"LOGIN_OK user={user} from={request.remote_addr}")
            return redirect(url_for('dashboard'))
        logging.warning(f"LOGIN_FAIL user={user} from={request.remote_addr}")
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
    bucket_list = [
        {'name': k, 'public': v['public'], 'objects': len(v['objects']),
         'created': v['created'][:10]}
        for k, v in BUCKETS.items()
    ]
    return render_template('dashboard.html', buckets=bucket_list, user=session['user'])

@app.route('/browser/<bucket_name>')
def browser(bucket_name):
    if 'user' not in session:
        return redirect(url_for('login'))
    b = BUCKETS.get(bucket_name)
    if not b:
        return "Bucket not found", 404
    objects = [{'key': k, 'size': v['size'], 'type': v['content_type'], 'modified': v['last_modified']}
               for k, v in b['objects'].items()]
    return render_template('browser.html', bucket=bucket_name, objects=objects, user=session['user'])

@app.route('/health')
def health():
    return jsonify({'status': 'healthy', 'service': 'pul-artifact-store'}), 200

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=9000, debug=False)
