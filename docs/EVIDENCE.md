# Evidence index — GRADING.md item by item

Every item from the Session 21 rubric (`GRADING.md`), with where it is in the code and the
screenshot that proves it. All screenshots are in [`evidence/screenshots/`](evidence/screenshots/).

- **Terminal screenshots** are rendered from the recorded session with the same name in
  [`evidence/transcripts/`](evidence/transcripts/): each command and its real output. The
  prompt `ratnesh@IdeaPad` is read from the machine.
- **`web-*`** files are headless-Chrome captures of the running UIs, with the URL bar.
- **`aws-*`** files are the student's own AWS Console screenshots.

`scripts/check-submission.sh` re-checks every item a script can verify (46 checks, all passing).

## M1 — Application (10)

| Criterion | Where | Proof |
|---|---|---|
| FastAPI starts, `/health` responds | [`backend/app/main.py`](../backend/app/main.py) | [m1-api](evidence/screenshots/m1-api_1.png) |
| ≥ 4 REST endpoints (GET, POST, PUT, DELETE) | `/api/books`, `/api/books/{id}`, `/api/books/{id}/reserve`, `/api/books/stats`, `/api/version` | [m1-api](evidence/screenshots/m1-api_1.png): every endpoint with its real status code (201, 200, 409, 204, 404, 422) |
| PostgreSQL table managed by Alembic | [`backend/alembic/versions/0001_create_books.py`](../backend/alembic/versions/0001_create_books.py) | [m1-api](evidence/screenshots/m1-api_1.png): rows in `books` and `alembic_version = 0001`; [m4-compose-up](evidence/screenshots/m4-compose-up.png): "Running upgrade -> 0001" |
| React frontend renders and calls the API | [`frontend/src/`](../frontend/src/) | [web-m1-m4-app-localhost-3000](evidence/screenshots/web-m1-m4-app-localhost-3000.png), [API docs](evidence/screenshots/web-m1-swagger-api-docs.png) |
| Responsive, usable UI | [`frontend/src/styles.css`](../frontend/src/styles.css) | same captures |

## M2 — Testing (10)

| Criterion | Where | Proof |
|---|---|---|
| `pytest` runs without errors; ≥ 5 tests on ≥ 3 endpoints | [`backend/tests/test_api.py`](../backend/tests/test_api.py) (11 tests) | [m2-pytest](evidence/screenshots/m2-pytest.png): each test PASSED, 95 % coverage |
| Test database, not production | [`backend/tests/conftest.py`](../backend/tests/conftest.py): in-memory SQLite | same screenshot (grep of conftest) |
| `pytest.ini` / `conftest.py` | [`backend/pytest.ini`](../backend/pytest.ini) | same screenshot |

## M3 — Git and GitHub (5)

| Criterion | Proof |
|---|---|
| Public repository | https://github.com/RatneshVaibhav/readcycle |
| Meaningful commit messages, ≥ 10 commits | [m3-git-history](evidence/screenshots/m3-git-history.png), [web-m3-github-commits](evidence/screenshots/web-m3-github-commits.png) |
| `.gitignore` excludes `.env`, `__pycache__`, `node_modules`, `.venv` | [`.gitignore`](../.gitignore); [m3-git-history](evidence/screenshots/m3-git-history.png) shows `git check-ignore` for each |

## M4 — Docker (10)

| Criterion | Where | Proof |
|---|---|---|
| `backend/Dockerfile` builds | [`backend/Dockerfile`](../backend/Dockerfile) | [m4-compose-up](evidence/screenshots/m4-compose-up.png) |
| `frontend/Dockerfile` multi-stage (Node build + nginx runtime) | [`frontend/Dockerfile`](../frontend/Dockerfile) | same |
| Images run as non-root | uid 10001 (backend), uid 101 (nginx) | [m4-compose-up](evidence/screenshots/m4-compose-up.png): `id` inside both containers |
| `docker compose up --build` starts frontend, backend, PostgreSQL | [`docker-compose.yml`](../docker-compose.yml) | [m4-compose-up](evidence/screenshots/m4-compose-up.png), [browser at localhost:3000](evidence/screenshots/web-m1-m4-app-localhost-3000.png) |

## M5 — CI/CD (15)

| Criterion | Where | Proof |
|---|---|---|
| Workflow in `.github/workflows/`, runs on push to `main` | [`pipeline.yml`](../.github/workflows/pipeline.yml) | [web-m5-actions-run-green](evidence/screenshots/web-m5-actions-run-green.png) |
| pytest as a job that fails the build | job `backend-test`, every later job `needs` it | same |
| Frontend built in the pipeline | job `frontend-build` | same |
| Both images built | job `docker-build` | same |
| Pushed to GHCR | job `push` | [web-m5-ghcr-readcycle-backend](evidence/screenshots/web-m5-ghcr-readcycle-backend.png), [frontend](evidence/screenshots/web-m5-ghcr-readcycle-frontend.png) |
| Tags are the commit SHA, never `latest` | `$GITHUB_SHA`; the chart *requires* a tag | the GHCR pages list only SHA tags |

Actions run URL: https://github.com/RatneshVaibhav/readcycle/actions (no run has failed: every one is green, or cancelled because a newer push superseded it; e.g.
[run #3](https://github.com/RatneshVaibhav/readcycle/actions/runs/38781771749)).

## M6 — DevSecOps (5)

| Criterion | Where | Proof |
|---|---|---|
| Trivy scans both images in CI | job `image-scan` scans the exact image tarballs that are pushed | [m6-trivy-in-pipeline](evidence/screenshots/m6-trivy-in-pipeline.png) (taken from the GitHub job log) |
| Pipeline fails on HIGH or CRITICAL | [`security/trivy.yaml`](../security/trivy.yaml) (HIGH, CRITICAL) + [`security-gate.sh`](../security/security-gate.sh) fails the job; nothing is pushed without the gate | same screenshot: gate table, all PASS |
| Explain a CVE / a clean result | see below | [m6-trivy-cve-example](evidence/screenshots/m6-trivy-cve-example.png) |

**What Trivy scanned and what it means (2–3 sentences):** Trivy scanned the operating-system
packages and the Python and Node dependencies inside both images, using the exact image files
the pipeline pushes, and found **0 HIGH or CRITICAL** vulnerabilities. That clean result is not
luck: the upstream nginx base image has **43 fixable HIGH/CRITICAL CVEs**, for example
**CVE-2026-33630**, a use-after-free / double-free in the `c-ares` DNS library (1.34.6, fixed
in 1.34.8). The frontend Dockerfile runs `apk upgrade` (and removes `curl`) to patch them, and
the gate would stop the pipeline if one came back.

## M7 — Terraform on AWS (15)

| Criterion | Where | Proof |
|---|---|---|
| `terraform/` with valid HCL; `init` succeeds | [`terraform/`](../terraform/) | [m7-terraform-plan](evidence/screenshots/m7-terraform-plan.png) |
| `plan`: non-empty, no errors | 25 resources to add | [m7-terraform-plan](evidence/screenshots/m7-terraform-plan.png), [full plan (IP and account masked)](evidence/raw/terraform-plan.txt) |
| VPC with ≥ 2 public subnets **provisioned** | [`vpc.tf`](../terraform/vpc.tf) | [aws-m7-console-vpc](evidence/screenshots/aws-m7-console-vpc.png), [aws-m7-console-subnets](evidence/screenshots/aws-m7-console-subnets.png) |
| EKS with ≥ 1 node group **provisioned** | [`eks.tf`](../terraform/eks.tf) | [aws-m7-console-eks-cluster](evidence/screenshots/aws-m7-console-eks-cluster.png), [aws-m7-console-eks-nodegroup](evidence/screenshots/aws-m7-console-eks-nodegroup.png), [apply](evidence/screenshots/m7-terraform-apply.png) (+ [node group fix](evidence/screenshots/m7-terraform-apply-nodegroup.png), [storage driver fix](evidence/screenshots/m7-terraform-apply-ebs-fix.png)) |
| `destroy` removes everything | | [m7-terraform-destroy](evidence/screenshots/m7-terraform-destroy_1.png) ([page 2](evidence/screenshots/m7-terraform-destroy_2.png)): 27 destroyed, 0 left; [m7-aws-nothing-left](evidence/screenshots/m7-aws-nothing-left.png): checked against AWS itself |
| `terraform.tfvars.example`, no credentials committed | [`terraform.tfvars.example`](../terraform/terraform.tfvars.example) | Gitleaks over the whole history: no leaks |

Region: **ap-southeast-2 (Sydney)**. The AWS account came from AWS's new sign-up experience, whose
AWS-managed policy allows EC2 and EKS only in the region AWS assigned to it. See the README.

## M8 — Kubernetes + Helm (15)

| Criterion | Where | Proof (on AWS EKS) | Proof (local cluster) |
|---|---|---|---|
| `k8s/namespace.yaml` applies | [`k8s/namespace.yaml`](../k8s/namespace.yaml) | [m8-eks-setup](evidence/screenshots/m8-eks-setup.png) | [m8-helm-install-local](evidence/screenshots/m8-helm-install-local.png) |
| Chart with `Chart.yaml`, `values.yaml`, templates | [`helm/readcycle/`](../helm/readcycle/) | | |
| `helm upgrade --install` works; `helm list` | | [m8-eks-helm-install](evidence/screenshots/m8-eks-helm-install.png) | [m8-helm-install-local](evidence/screenshots/m8-helm-install-local.png) |
| Backend and frontend ≥ 2 replicas, pods Running | HPA min 2; frontend 2 | [m8-eks-helm-install](evidence/screenshots/m8-eks-helm-install.png) | same |
| ClusterIP Services | | same (`kubectl get svc`) | same |
| Ingress: `/` → frontend, `/api` → backend | [`templates/ingress.yaml`](../helm/readcycle/templates/ingress.yaml) | [m8-eks-ingress](evidence/screenshots/m8-eks-ingress.png), [browser on EKS](evidence/screenshots/web-m8-eks-app-via-ingress.png) | [m8-ingress-routing](evidence/screenshots/m8-ingress-routing.png), [browser](evidence/screenshots/web-m8-app-via-ingress-local.png) |
| HPA (instructor README) | [`templates/backend-hpa.yaml`](../helm/readcycle/templates/backend-hpa.yaml) | | [m9-promql-and-hpa](evidence/screenshots/m9-promql-and-hpa.png): 2 → 4 under load |

## M9 — Observability (10)

| Criterion | Proof |
|---|---|
| `/metrics` returns Prometheus format | [m9-metrics-curl](evidence/screenshots/m9-metrics-curl.png) |
| Prometheus installed and scraping the app | [web-m9-prometheus-targets-up](evidence/screenshots/web-m9-prometheus-targets-up.png) (4/4 UP), on EKS: [web-m9-eks-prometheus-targets-up](evidence/screenshots/web-m9-eks-prometheus-targets-up.png); [m9-promql-and-hpa](evidence/screenshots/m9-promql-and-hpa.png) |
| Grafana installed and accessible | [m9-monitoring-install](evidence/screenshots/m9-monitoring-install.png) |
| A Grafana panel with live application metrics | [web-m9-grafana-dashboard](evidence/screenshots/web-m9-grafana-dashboard.png), on EKS: [web-m9-eks-grafana-dashboard](evidence/screenshots/web-m9-eks-grafana-dashboard.png) |
| `monitoring/` values files | [`monitoring/kube-prometheus-stack-values.yaml`](../monitoring/kube-prometheus-stack-values.yaml); alert rules: [web-m9-prometheus-alert-rules](evidence/screenshots/web-m9-prometheus-alert-rules.png) |

## M10 — Documentation and live demo (5)

| Criterion | Proof |
|---|---|
| `README.md` in the root, explaining the application | [README](../README.md) |
| Live demo: commit → pipeline → deployment updates | demo script: [DEMO.md](DEMO.md). Rehearsal recorded: [before](evidence/screenshots/web-m10-1-before.png) → [commit and push](evidence/screenshots/m10-live-demo-1-commit.png) → [pipeline running](evidence/screenshots/web-m10-2-pipeline-running.png) → [pipeline green, promoted, rolled out](evidence/screenshots/m10-live-demo-2-rollout.png) → [after](evidence/screenshots/web-m10-3-after.png) → [Argo CD](evidence/screenshots/web-m10-4-argocd-synced.png): pushed 08:51:45, live 08:57:34 |

## Homework extras (Session 21 assignment)

| Requirement | Proof |
|---|---|
| ConfigMap, Secret, probes, storage | [`helm/readcycle/templates/`](../helm/readcycle/templates/); PVC on gp3 EBS in [m8-eks-helm-install](evidence/screenshots/m8-eks-helm-install.png) |
| SAST, SCA, secret scanning, security gate | [m6-trivy-in-pipeline](evidence/screenshots/m6-trivy-in-pipeline.png) (8-report gate table) |
| GitOps workflow | [m10-gitops-bootstrap](evidence/screenshots/m10-gitops-bootstrap.png), [m10-gitops-synced](evidence/screenshots/m10-gitops-synced.png) |
| Troubleshooting challenge | [troubleshooting/README.md](../troubleshooting/README.md) |
