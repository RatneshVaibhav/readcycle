#!/usr/bin/env bash
# check-submission.sh - check this repository against the Session 21 GRADING.md submission
# checklist (every item that a script can verify). Prints PASS/FAIL per item; exit 1 if any fail.
# The course has no official grader script; this is a self-check, not the grade.
#   scripts/check-submission.sh
set -uo pipefail
cd "$(dirname "$0")/.."
pass=0; fail=0
check() {  # check <module> <description> <command...>
  local module="$1" what="$2"; shift 2
  if "$@" >/dev/null 2>&1; then printf "  PASS  %-4s %s\n" "$module" "$what"; pass=$((pass + 1))
  else printf "  FAIL  %-4s %s\n" "$module" "$what"; fail=$((fail + 1)); fi
}
evidence() { for f in "$@"; do [ -s "docs/evidence/screenshots/$f" ] || return 1; done; }
PYTEST="$PWD/backend/.venv/bin/pytest"; [ -x "$PYTEST" ] || PYTEST="python3 -m pytest"
TAG=$(grep -oP 'tag: "\K[0-9a-f]{40}' gitops/environments/dev/values.yaml)

echo "== M1 Application"
check M1 "backend/app, alembic migration, requirements.txt, frontend/, docker-compose.yml" \
  bash -c 'ls backend/app/*.py && ls backend/alembic/versions/*.py && [ -f backend/requirements.txt ] && [ -d frontend/src ] && [ -f docker-compose.yml ]'
check M1 "REST endpoints with GET, POST, PUT and DELETE (at least 4)" \
  bash -c '[ "$(grep -cE "@app\.(get|post|put|delete)\(\"/api/" backend/app/main.py)" -ge 4 ] && for m in get post put delete; do grep -q "@app.$m(\"/api/" backend/app/main.py || exit 1; done'
check M1 "/health endpoint" grep -q '@app.get("/health"' backend/app/main.py

echo "== M2 Testing"
check M2 "pytest.ini or conftest.py present" bash -c '[ -f backend/pytest.ini ] || [ -f backend/tests/conftest.py ]'
check M2 "tests use an in-memory SQLite database, not PostgreSQL" grep -q 'sqlite' backend/tests/conftest.py
check M2 "pytest passes with at least 5 tests" \
  bash -c "cd backend && out=\$($PYTEST -q 2>&1) && n=\$(echo \"\$out\" | grep -oP '\\d+(?= passed)') && [ \"\$n\" -ge 5 ]"

echo "== M3 Git and GitHub"
check M3 "at least 10 commits" bash -c '[ "$(git rev-list --count HEAD)" -ge 10 ]'
check M3 ".gitignore excludes .env, __pycache__, node_modules, .venv" \
  bash -c 'for p in .env backend/app/__pycache__ frontend/node_modules backend/.venv; do git check-ignore -q "$p" || exit 1; done'
check M3 "GitHub repository is public" \
  bash -c 'curl -sf https://api.github.com/repos/RatneshVaibhav/readcycle | grep -q "\"private\": false"'

echo "== M4 Docker"
check M4 "backend/Dockerfile and frontend/Dockerfile" bash -c '[ -f backend/Dockerfile ] && [ -f frontend/Dockerfile ]'
check M4 "frontend/Dockerfile is multi-stage (Node build + nginx runtime)" \
  bash -c 'grep -q "^FROM node" frontend/Dockerfile && grep -q "^FROM nginx" frontend/Dockerfile'
check M4 "both images end with a non-root USER" \
  bash -c 'for f in backend/Dockerfile frontend/Dockerfile; do u=$(grep "^USER" $f | tail -1 | cut -d" " -f2); [ -n "$u" ] && [ "$u" != root ] && [ "$u" != 0 ] || exit 1; done'
check M4 "docker-compose.yml defines frontend, backend and a PostgreSQL service" \
  bash -c 'DB_PASSWORD=x docker compose config --services | sort | tr "\n" " " | grep -q "backend db frontend"'

echo "== M5 CI/CD"
W=.github/workflows/pipeline.yml
check M5 "workflow triggers on push to main" bash -c "grep -A2 '^  push:' $W | grep -q 'branches: \[main\]'"
check M5 "pytest runs as a pipeline job" grep -q 'pytest -v' $W
check M5 "frontend is built in the pipeline" grep -q 'npm run build' $W
check M5 "both images are built" bash -c "grep -q 'readcycle-backend' $W && grep -q 'readcycle-frontend' $W && grep -q 'docker build' $W"
check M5 "images are pushed to GHCR tagged with the commit SHA" \
  bash -c "grep -q \"ghcr.io\" $W && grep -q 'docker push' $W && grep -q 'GITHUB_SHA' $W"
check M5 "the promoted image exists in GHCR (public, SHA tag)" \
  bash -c "tok=\$(curl -s 'https://ghcr.io/token?scope=repository:ratneshvaibhav/readcycle-backend:pull' | jq -r .token); curl -sf -H \"Authorization: Bearer \$tok\" https://ghcr.io/v2/ratneshvaibhav/readcycle-backend/tags/list | grep -q $TAG"

echo "== M6 DevSecOps"
check M6 "Trivy scans both images in the pipeline" bash -c "grep -q 'trivy image' $W && grep -q 'for img in backend frontend' $W"
check M6 "pipeline fails on HIGH/CRITICAL (Trivy severity + security gate)" \
  bash -c "grep -q 'HIGH' security/trivy.yaml && grep -q 'HIGH/CRITICAL' security/security-gate.sh && grep -q 'security-gate.sh' $W"
check M6 "no secrets anywhere in the Git history (Gitleaks)" gitleaks git . --no-banner --redact --log-level error

echo "== M7 Terraform"
check M7 "terraform/ has HCL files and terraform.tfvars.example" bash -c 'ls terraform/*.tf && [ -f terraform/terraform.tfvars.example ]'
check M7 "no tfvars, state or plan files tracked by Git" \
  bash -c '! git ls-files | grep -E "\.tfvars$|\.tfstate|tfplan"'
check M7 "terraform fmt and validate" bash -c 'cd terraform && terraform init -backend=false -input=false >/dev/null && terraform fmt -check -recursive && terraform validate'
check M7 "VPC with at least two public subnets and an EKS cluster with a node group" \
  bash -c 'grep -q "resource \"aws_vpc\"" terraform/vpc.tf && grep -q "resource \"aws_subnet\" \"public\"" terraform/vpc.tf && grep -A3 "variable \"azs\"" terraform/variables.tf | grep -q "\"a\", \"b\"" && grep -q "resource \"aws_eks_cluster\"" terraform/eks.tf && grep -q "resource \"aws_eks_node_group\"" terraform/eks.tf'

echo "== M8 Kubernetes + Helm"
check M8 "k8s/namespace.yaml is a Namespace" bash -c 'python3 -c "import yaml,sys; d=yaml.safe_load(open(\"k8s/namespace.yaml\")); sys.exit(d[\"kind\"]!=\"Namespace\")"'
check M8 "Helm chart with Chart.yaml, values.yaml and templates/" bash -c '[ -f helm/readcycle/Chart.yaml ] && [ -f helm/readcycle/values.yaml ] && [ -d helm/readcycle/templates ]'
check M8 "helm lint passes" helm lint helm/readcycle --set image.tag="$TAG"
R=$(mktemp); trap 'rm -f "$R"' EXIT
helm template readcycle helm/readcycle --set image.tag="$TAG" > "$R" 2>/dev/null
check M8 "backend (HPA min 2) and frontend run at least 2 replicas" \
  bash -c "grep -q 'minReplicas: 2' $R && python3 -c \"import yaml,sys; d=[x for x in yaml.safe_load_all(open('$R')) if x and x['kind']=='Deployment' and x['metadata']['name'].endswith('frontend')]; sys.exit(d[0]['spec']['replicas']<2)\""
check M8 "Services are ClusterIP" bash -c "! python3 -c \"import yaml,sys; s=[x for x in yaml.safe_load_all(open('$R')) if x and x['kind']=='Service' and x['spec'].get('type','ClusterIP')!='ClusterIP']; sys.exit(0 if s else 1)\""
check M8 "Ingress routes / to the frontend and /api to the backend" \
  bash -c "python3 -c \"import yaml,sys; i=[x for x in yaml.safe_load_all(open('$R')) if x and x['kind']=='Ingress'][0]; p={q['path']:q['backend']['service']['name'] for q in i['spec']['rules'][0]['http']['paths']}; sys.exit(not (p.get('/','').endswith('frontend') and p.get('/api','').endswith('backend')))\""

echo "== M9 Observability"
check M9 "/metrics is exposed (prometheus-fastapi-instrumentator) and tested" \
  bash -c 'grep -q "Instrumentator" backend/app/main.py && grep -q "/metrics" backend/tests/test_api.py'
check M9 "monitoring/ holds the Prometheus + Grafana Helm values" bash -c 'ls monitoring/*values*.yaml'
check M9 "the chart ships a ServiceMonitor" grep -q 'kind: ServiceMonitor' "$R"

echo "== M10 Documentation"
check M10 "README.md in the repository root" test -s README.md

echo "== Evidence files (docs/evidence/screenshots)"
check M1 "app in the browser" evidence web-m1-m4-app-localhost-3000.png
check M2 "pytest -v" evidence m2-pytest.png
check M3 "commit history" evidence m3-git-history.png web-m3-github-commits.png
check M4 "docker compose up --build and localhost:3000" evidence m4-compose-up.png web-m1-m4-app-localhost-3000.png
check M5 "green Actions run and GHCR packages" evidence web-m5-actions-run-green.png web-m5-ghcr-readcycle-backend.png web-m5-ghcr-readcycle-frontend.png
check M6 "Trivy output from a pipeline run" evidence m6-trivy-in-pipeline.png
check M7 "terraform plan, AWS Console VPC + EKS, terraform destroy" \
  evidence m7-terraform-plan.png aws-m7-console-vpc.png aws-m7-console-eks-cluster.png m7-terraform-destroy.png
check M8 "kubectl get pods / svc, helm list, app through the Ingress" \
  evidence m8-eks-helm-install.png web-m8-eks-app-via-ingress.png
check M9 "curl /metrics, Prometheus targets UP, Grafana dashboard" \
  evidence m9-metrics-curl.png web-m9-prometheus-targets-up.png web-m9-grafana-dashboard.png
check M10 "live demo rehearsal: before, pipeline, after" evidence web-m10-1-before.png web-m10-2-pipeline-running.png web-m10-3-after.png

echo
echo "RESULT: $pass passed, $fail failed"
[ "$fail" -eq 0 ]
