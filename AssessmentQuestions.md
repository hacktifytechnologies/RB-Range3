# Assessment Questions — RNG-DEV-01 · VIKAS TANTRA
## OPERATION GRIDFALL | Prabal Urja Limited NEXUS-IT

> **Scoring Policy:** No flags. All answers are discovered only by successfully exploiting the vulnerability on each machine. MCQ answers represent specific technical findings; FIB answers are exact strings discoverable during exploitation only.

---

## M1 — dev-jenkins (Jenkins CI/CD · Port 8080)

**Q1.1 [MCQ]** Which Jenkins REST API endpoint, when queried anonymously, returns a JSON listing of all build jobs with their latest build status?

- A) `/api/v2/jobs`
- B) `/api/json?tree=jobs[name,lastBuild[result,artifacts[*]]]`
- C) `/jobs/list`
- D) `/build/status/all`

**Answer:** B

---

**Q1.2 [MCQ]** The `pul-firmware-build` job archives its artefacts on successful builds. What is the exact filename of the ZIP archive available for download from the last successful build?

- A) `build-config.zip`
- B) `jenkins-creds.tar.gz`
- C) `deploy-bundle.zip`
- D) `firmware-artefacts.zip`

**Answer:** C

---

**Q1.3 [MCQ]** Which Jenkins global configuration parameter, when set to `false`, disables all authentication and authorisation — allowing any unauthenticated HTTP client to read jobs, download artefacts, and interact with the API?

- A) `authEnabled`
- B) `securityEnabled`
- C) `useSecurity`
- D) `enableAuth`

**Answer:** C

---

**Q1.4 [FIB]** What is the username stored in the Docker registry credential found inside the build artefact `docker-config.json`?

**Answer:** `pul-registry-svc`

---

**Q1.5 [FIB]** What is the Jenkins URL path used to download a specific archived artefact file (`docker-config.json`) from the last successful build of the `pul-firmware-build` job?

**Answer:** `/job/pul-firmware-build/lastSuccessfulBuild/artifact/deploy-bundle/docker-config.json`

---

## M2 — dev-registry (Container Registry · Port 5000)

**Q2.1 [MCQ]** Which Docker Registry v2 API endpoint, accessible without any credentials, lists all image repositories hosted on the registry?

- A) `/v2/list`
- B) `/v2/images`
- C) `/v2/_catalog`
- D) `/v2/repos`

**Answer:** C

---

**Q2.2 [MCQ]** Which image repository in the PUL container registry contains the MinIO artifact store credentials embedded in its image configuration blob?

- A) `pul/sonar-runner`
- B) `pul/firmware-builder`
- C) `pul/registry-agent`
- D) `pul/deploy-tools`

**Answer:** B

---

**Q2.3 [MCQ]** In a Docker image OCI manifest, which JSON field within the image configuration blob (retrieved via the `/v2/{name}/blobs/{digest}` endpoint) contains the environment variable list where credentials are embedded?

- A) `Labels`
- B) `Entrypoint`
- C) `Volumes`
- D) `Env`

**Answer:** D

---

**Q2.4 [FIB]** What is the MinIO access key (username) found in the `pul/firmware-builder:latest` image configuration blob's environment variable list?

**Answer:** `pul-build-svc`

---

**Q2.5 [FIB]** What is the TCP port on which the PUL Build Artifact Store (MinIO-compatible) is running, as disclosed by the image ENV layer?

**Answer:** `9000`

---

## M3 — dev-artifacts (Build Artifact Store · Port 9000)

**Q3.1 [MCQ]** When a MinIO/S3-compatible bucket has a `public-read` ACL policy misconfiguration, which HTTP request method and URL pattern can be used to list all objects within the bucket without any authentication headers?

- A) `POST /api/v1/list?bucket=<name>`
- B) `GET /<bucket-name>/?list-type=2`
- C) `GET /api/v1/objects/<bucket-name>`
- D) `PUT /<bucket-name>/list`

**Answer:** B

---

**Q3.2 [MCQ]** Which bucket in the PUL Build Artifact Store has been misconfigured with a public-read ACL, making its contents listable and downloadable without authentication?

- A) `pul-build-cache`
- B) `pul-firmware-releases`
- C) `pul-deploy-configs`
- D) `pul-code-reports`

**Answer:** D

---

**Q3.3 [MCQ]** What is the object key (path) within the public bucket that contains the SonarQube admin access credentials?

- A) `sonar-webhook.json`
- B) `deploy-configs/sonar.env`
- C) `sonar-integration/sonarqube-access.env`
- D) `ci-config/sonar-token.txt`

**Answer:** C

---

**Q3.4 [FIB]** What is the exact SonarQube admin token found in the `sonarqube-access.env` file retrieved from the public bucket?

**Answer:** `sqa_pul_admin_2024_gridfall`

---

**Q3.5 [FIB]** What MIME content-type is returned by the artifact store server when the `sonarqube-access.env` object is downloaded directly via HTTP?

**Answer:** `text/plain`

---

## M4 — dev-sonar (Code Intelligence Portal · Port 9200)

**Q4.1 [MCQ]** Which SonarQube REST API endpoint, when called with a valid admin authentication token, returns all configuration settings for a specified project component — including CI/CD integration tokens stored in plain text?

- A) `/api/config/list`
- B) `/api/settings/values`
- C) `/api/integration/keys`
- D) `/api/project/settings`

**Answer:** B

---

**Q4.2 [MCQ]** What is the exact `component` query parameter value used in the settings API call to retrieve configuration for the PUL OTA firmware project?

- A) `pul-firmware-build`
- B) `pul-firmware`
- C) `firmware-ota-prod`
- D) `pul-firmware-ota`

**Answer:** D

---

**Q4.3 [MCQ]** Which specific setting key within the API response contains the Deploy Commander API token in plain text?

- A) `sonar.deploy.api_key`
- B) `sonar.ci.api_token`
- C) `sonar.webhook.secret`
- D) `sonar.ci.deploy_token`

**Answer:** D

---

**Q4.4 [FIB]** What is the exact Deploy Commander API token value extracted from the SonarQube `/api/settings/values` response?

**Answer:** `dc-pul-deploy-2024-gridfall`

---

**Q4.5 [FIB]** What HTTP header must be included in the SonarQube API request to authenticate using the admin token extracted from M3?

**Answer:** `Authorization: Bearer sqa_pul_admin_2024_gridfall`

---

## M5 — dev-deploy (Deploy Commander · Port 8888)

**Q5.1 [MCQ]** Which query parameter must be added to the Deploy Commander sync API call (`POST /api/applications/{name}/sync`) to trigger a dry-run that returns the full resolved Kubernetes manifest without applying it to the cluster?

- A) `simulate=true`
- B) `preview=1`
- C) `dryRun=true`
- D) `noapply=true`

**Answer:** C

---

**Q5.2 [MCQ]** In the Kubernetes manifest returned by the dry-run API, which resource `Kind` contains the base64-encoded ServiceAccount token used to authenticate against the production cluster?

- A) `ConfigMap`
- B) `ServiceAccount`
- C) `ClusterRole`
- D) `Secret`

**Answer:** D

---

**Q5.3 [MCQ]** What is the Kubernetes Secret `type` field value for the ServiceAccount token Secret returned in the dry-run manifest — the value that identifies it as a service account credential?

- A) `Opaque`
- B) `kubernetes.io/tls`
- C) `kubernetes.io/service-account-token`
- D) `kubernetes.io/dockerconfigjson`

**Answer:** C

---

**Q5.4 [FIB]** What is the name of the application used in the dry-run sync API call that returns the Kubernetes manifest containing the ServiceAccount token?

**Answer:** `pul-ota-firmware`

---

**Q5.5 [FIB]** What is the network zone prefix (first octet) of the Kubernetes cluster API server endpoint (`https://<IP>:6443`) revealed in the dry-run manifest's kubeconfig, identifying it as the v-Private cloud zone?

**Answer:** `193`

---

*Assessment Questions | RNG-DEV-01 · VIKAS TANTRA | OPERATION GRIDFALL*
*© 2026 Hacktify Cybersecurity — Exercise Use Only*
