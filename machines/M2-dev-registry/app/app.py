#!/usr/bin/env python3
"""
PUL Container Registry — M2 · dev-registry
Docker Registry v2 API Mock
OPERATION GRIDFALL | RNG-DEV-01 · VIKAS TANTRA
Vulnerability: Unauthenticated Docker Registry v2 API + credentials in image config ENV blob
MITRE: T1552.001 (Credentials in Files) · T1613 (Container and Resource Discovery)
"""

from flask import Flask, request, jsonify, render_template, redirect, url_for, Response
import json, hashlib, logging, os, datetime

app = Flask(__name__)
LOG_DIR = '/var/log/pul-registry'
os.makedirs(LOG_DIR, exist_ok=True)
logging.basicConfig(
    filename=f'{LOG_DIR}/registry.log', level=logging.INFO,
    format='%(asctime)s [%(levelname)s] %(message)s'
)

# ── Registry data ──────────────────────────────────────────────────────────────
REGISTRY_AUTH = {
    'pul-registry-svc': 'Rg5try@PUL!Bld24',
    'pul-admin': 'Adm1n@Rg5try!PUL',
}

CATALOG = {"repositories": ["pul/firmware-builder", "pul/sonar-runner"]}

TAGS = {
    "pul/firmware-builder": {"name": "pul/firmware-builder", "tags": ["latest", "v3.2.1", "v3.1.0", "v3.0.5"]},
    "pul/sonar-runner":     {"name": "pul/sonar-runner",     "tags": ["latest", "v2.0.0"]},
}

# Pre-computed digests
FB_CONFIG_DIGEST = "sha256:a4f3c2b1e8d7a6f5e4d3c2b1a0f9e8d7c6b5a4f3e2d1c0b9a8f7e6d5c4b3a2f1"
FB_LAYER1_DIGEST = "sha256:b5e4d3c2b1a0f9e8d7c6b5a4f3e2d1c0b9a8f7e6d5c4b3a2f1e0d9c8b7a6f5e4"
SR_CONFIG_DIGEST = "sha256:c6f5e4d3c2b1a0f9e8d7c6b5a4f3e2d1c0b9a8f7e6d5c4b3a2f1e0d9c8b7a6f5"

# The vulnerable firmware-builder image config blob (contains MinIO credentials in Env)
FIRMWARE_BUILDER_CONFIG = {
    "architecture": "amd64",
    "os": "linux",
    "created": "2024-11-10T06:30:00.000000000Z",
    "author": "devops@prabalurja.in",
    "config": {
        "User": "build",
        "ExposedPorts": {},
        "Env": [
            "PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin",
            "GOPATH=/go",
            "GO_VERSION=1.21.4",
            "BUILD_TARGET=pul-firmware",
            "ARTIFACT_STORE_HOST=11.x.x.x",
            "ARTIFACT_STORE_PORT=9000",
            "MINIO_ACCESS_KEY=pul-build-svc",
            "MINIO_SECRET_KEY=Artf@ct5tr!PUL24",
            "MINIO_BUCKET=pul-firmware-releases",
            "BUILD_ENV=production",
            "FIRMWARE_VERSION=3.2.1",
            "OTA_CHANNEL=stable"
        ],
        "Cmd": ["/bin/bash", "-c", "/opt/pul/build.sh"],
        "WorkingDir": "/workspace",
        "Labels": {
            "maintainer": "devops@prabalurja.in",
            "org.pul.image.name": "firmware-builder",
            "org.pul.image.version": "3.2.1",
            "org.pul.image.description": "PUL NEXUS-IT firmware build container",
            "note": "TODO: migrate MINIO_* vars to Vault runtime injection (DEVOPS-2847)"
        }
    },
    "rootfs": {
        "type": "layers",
        "diff_ids": [FB_LAYER1_DIGEST]
    },
    "history": [
        {"created": "2024-09-01T00:00:00Z", "created_by": "FROM ubuntu:22.04"},
        {"created": "2024-11-01T06:00:00Z", "created_by": "RUN apt-get update && apt-get install -y golang-1.21"},
        {"created": "2024-11-01T06:05:00Z", "created_by": "ENV ARTIFACT_STORE_HOST=11.x.x.x ARTIFACT_STORE_PORT=9000 MINIO_ACCESS_KEY=pul-build-svc MINIO_SECRET_KEY=Artf@ct5tr!PUL24"},
        {"created": "2024-11-10T06:25:00Z", "created_by": "COPY build.sh /opt/pul/"},
        {"created": "2024-11-10T06:30:00Z", "created_by": "CMD [\"/bin/bash\", \"-c\", \"/opt/pul/build.sh\"]"}
    ]
}

SONAR_RUNNER_CONFIG = {
    "architecture": "amd64",
    "os": "linux",
    "created": "2024-11-05T09:00:00.000000000Z",
    "config": {
        "Env": [
            "PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin",
            "JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64",
            "SONAR_SCANNER_VERSION=5.0.1",
            "SONAR_HOST=11.x.x.x",
            "SONAR_PORT=9200",
            "BUILD_ENV=production"
        ],
        "Labels": {
            "maintainer": "devops@prabalurja.in",
            "org.pul.image.name": "sonar-runner"
        }
    }
}

MANIFESTS = {
    "pul/firmware-builder": {
        "latest": {
            "schemaVersion": 2,
            "mediaType": "application/vnd.docker.distribution.manifest.v2+json",
            "config": {
                "mediaType": "application/vnd.docker.container.image.v1+json",
                "size": len(json.dumps(FIRMWARE_BUILDER_CONFIG)),
                "digest": FB_CONFIG_DIGEST
            },
            "layers": [
                {
                    "mediaType": "application/vnd.docker.image.rootfs.diff.tar.gzip",
                    "size": 29534232,
                    "digest": FB_LAYER1_DIGEST
                }
            ]
        }
    },
    "pul/sonar-runner": {
        "latest": {
            "schemaVersion": 2,
            "mediaType": "application/vnd.docker.distribution.manifest.v2+json",
            "config": {
                "mediaType": "application/vnd.docker.container.image.v1+json",
                "size": len(json.dumps(SONAR_RUNNER_CONFIG)),
                "digest": SR_CONFIG_DIGEST
            },
            "layers": []
        }
    }
}
# Add version tags pointing to same manifest
for name in ["pul/firmware-builder"]:
    for tag in ["v3.2.1", "v3.1.0", "v3.0.5"]:
        MANIFESTS[name][tag] = MANIFESTS[name]["latest"]
MANIFESTS["pul/sonar-runner"]["v2.0.0"] = MANIFESTS["pul/sonar-runner"]["latest"]

BLOBS = {
    FB_CONFIG_DIGEST: json.dumps(FIRMWARE_BUILDER_CONFIG),
    SR_CONFIG_DIGEST: json.dumps(SONAR_RUNNER_CONFIG),
    FB_LAYER1_DIGEST: "BINARY_LAYER_DATA_PLACEHOLDER",
}

# ── Registry v2 API ────────────────────────────────────────────────────────────

@app.after_request
def add_registry_header(resp):
    resp.headers['Docker-Distribution-Api-Version'] = 'registry/2.0'
    resp.headers['X-Content-Type-Options'] = 'nosniff'
    return resp

@app.route('/v2/', methods=['GET'])
def v2_base():
    logging.info(f"V2_BASE from={request.remote_addr}")
    return jsonify({}), 200

@app.route('/v2/_catalog', methods=['GET'])
def v2_catalog():
    logging.info(f"CATALOG from={request.remote_addr}")
    return jsonify(CATALOG), 200

@app.route('/v2/<path:name>/tags/list', methods=['GET'])
def v2_tags(name):
    logging.info(f"TAGS name={name} from={request.remote_addr}")
    if name in TAGS:
        return jsonify(TAGS[name]), 200
    return jsonify({"errors": [{"code": "NAME_UNKNOWN", "message": "repository name not known to registry"}]}), 404

@app.route('/v2/<path:name>/manifests/<string:reference>', methods=['GET', 'HEAD'])
def v2_manifest(name, reference):
    logging.info(f"MANIFEST name={name} ref={reference} from={request.remote_addr}")
    repo = MANIFESTS.get(name, {})
    manifest = repo.get(reference)
    if not manifest:
        return jsonify({"errors": [{"code": "MANIFEST_UNKNOWN", "message": "manifest unknown"}]}), 404
    resp = jsonify(manifest)
    resp.headers['Content-Type'] = 'application/vnd.docker.distribution.manifest.v2+json'
    resp.headers['Docker-Content-Digest'] = manifest['config']['digest']
    return resp

@app.route('/v2/<path:name>/blobs/<string:digest>', methods=['GET'])
def v2_blob(name, digest):
    logging.info(f"BLOB name={name} digest={digest} from={request.remote_addr}")
    blob = BLOBS.get(digest)
    if not blob:
        return jsonify({"errors": [{"code": "BLOB_UNKNOWN", "message": "blob unknown to registry"}]}), 404
    if digest == FB_LAYER1_DIGEST:
        return Response(blob, content_type='application/octet-stream')
    return Response(blob, content_type='application/vnd.docker.container.image.v1+json')

# ── Web UI ─────────────────────────────────────────────────────────────────────

@app.route('/')
def index():
    return redirect(url_for('ui_dashboard'))

@app.route('/ui/')
@app.route('/ui')
def ui_dashboard():
    repos = [
        {'name': 'pul/firmware-builder', 'tags': 4, 'pulls': 1247, 'size': '284 MB', 'updated': '2024-11-10', 'description': 'PUL NEXUS-IT firmware build container'},
        {'name': 'pul/sonar-runner', 'tags': 2, 'pulls': 389, 'size': '512 MB', 'updated': '2024-11-05', 'description': 'SonarScanner for PUL code intelligence pipelines'},
    ]
    stats = {'repos': 2, 'tags': 6, 'total_pulls': 1636, 'storage': '796 MB'}
    return render_template('ui.html', repos=repos, stats=stats)

@app.route('/ui/repo/<path:name>')
def ui_repo(name):
    tag_list = TAGS.get(name, {}).get('tags', [])
    manifest = MANIFESTS.get(name, {}).get('latest', {})
    return render_template('repo.html', name=name, tags=tag_list, manifest=manifest)

# ── Health ─────────────────────────────────────────────────────────────────────

@app.route('/health')
def health():
    return jsonify({'status': 'healthy', 'service': 'pul-container-registry', 'version': '2.0'}), 200

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=False)
