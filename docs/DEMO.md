# Live demo script (M10)

About 12 minutes, in the order the course asks for: application → Git commit → CI → image →
security scan → registry → Terraform → Kubernetes → Helm → Ingress → autoscaling → monitoring →
troubleshooting. The demo runs on the laptop's free local Kubernetes cluster, managed by Argo CD
from GitHub. The AWS part is shown from code and recorded evidence, because the EKS cluster was
destroyed after testing so it costs nothing.

## 15 minutes before

```bash
cd ~/readcycle                            # every command below runs from the repository
docker desktop start                      # Docker Desktop (wait ~1 minute)
docker start readcycle-control-plane      # the local Kubernetes cluster
kubectl get pods -A                       # wait until everything is Running
kubectl get application readcycle-dev -n argocd   # Synced / Healthy
curl -s http://readcycle.localhost:8088/api/version
```

Open these browser tabs:

| Tab | URL |
|---|---|
| App | http://readcycle.localhost:8088 |
| GitHub Actions | https://github.com/RatneshVaibhav/readcycle/actions |
| GHCR package | https://github.com/users/RatneshVaibhav/packages/container/package/readcycle-backend |
| Argo CD | http://argocd.localhost:8088/applications/argocd/readcycle-dev |
| Grafana | http://grafana.localhost:8088/d/readcycle/readcycle-service-overview |
| Prometheus targets | http://prometheus.localhost:8088/targets?search=readcycle-backend |

Close other heavy browser tabs: Docker on this laptop has only 3.2 GB of memory.

## The demo

**1. The application (1 min).** In the App tab, list a book, then reserve one.
*"ReadCycle is a campus textbook exchange: React frontend, FastAPI backend, PostgreSQL.
The footer shows which Git commit is running right now."* Point at `build xxxxxxx`.

**2. Make a change and push (1 min).** Change any visible text, for example the tagline in
`frontend/src/App.jsx`, then:

```bash
git commit -am "Change the tagline for the demo" && git push
```

*"From here nothing is manual: tests, scans, image build, registry, deployment."*

**3. Watch the pipeline (5 min; talk through it).** Open the run in the Actions tab.
*"Tests and the frontend build run first; if pytest fails, nothing after it runs. Then
Bandit and Semgrep scan the code, pip-audit and npm audit the dependencies, Gitleaks the
history. Both Docker images are built once, and Trivy scans the exact image files that will be
pushed. A security gate reads all eight reports and stops on any HIGH or CRITICAL finding. Then
the images go to GHCR tagged with the commit SHA, the chart is installed in a throw-away cluster
and `helm test` must pass, and the last job commits the new tag to `gitops/`."*
While it runs, show the GHCR tab (SHA tags only, never `latest`).

**4. GitOps rollout (1 min).** In the Argo CD tab: *"Argo CD watches the repository; it sees
the pipeline's commit and rolls out the new images. No one ran `kubectl` and GitHub holds no
cluster credentials."* Refresh the App tab: the new text, and **a new build in the footer**.
(Right after a rollout Argo CD may show "Degraded" for about a minute while the autoscaler waits
for CPU metrics of the new pods. That is expected.)

**5. Terraform and AWS (1.5 min).** Show [`terraform/`](../terraform/) and the recorded
evidence: [plan](evidence/screenshots/m7-terraform-plan.png) (25 resources),
[VPC](evidence/screenshots/aws-m7-console-vpc.png), [subnets](evidence/screenshots/aws-m7-console-subnets.png),
[EKS cluster](evidence/screenshots/aws-m7-console-eks-cluster.png),
[node group](evidence/screenshots/aws-m7-console-eks-nodegroup.png),
[app on EKS](evidence/screenshots/web-m8-eks-app-via-ingress.png),
[destroy](evidence/screenshots/m7-terraform-destroy_1.png).
*"Terraform built a VPC with two public and two private subnets, a NAT gateway and an EKS
cluster in Sydney; I deployed the same chart there, then destroyed everything so there are no
costs."*

**6. Kubernetes, Helm, Ingress (1 min).**

```bash
kubectl get pods -n readcycle
kubectl get svc -n readcycle
kubectl get ingress -n readcycle
```

*"Two backend and two frontend replicas, ClusterIP services, PostgreSQL as a StatefulSet with a
volume. The Ingress sends `/` to the frontend and `/api` to the backend."* (On the local cluster
the release is managed by Argo CD; the `helm list` output is in
[the evidence](evidence/screenshots/m8-eks-helm-install.png).)

**7. Autoscaling and monitoring (1.5 min).**

```bash
kubectl get hpa -n readcycle
monitoring/traffic.sh 120 2 &    # two minutes of traffic
kubectl get hpa -n readcycle -w  # watch replicas go up (Ctrl+C to stop)
```

Show the Prometheus targets (UP) and the Grafana dashboard: request rate, latency, replicas.

**8. Troubleshooting live (2 min).** The safest fault to break live is the Ingress host typo:

```bash
troubleshooting/inject.sh troubleshooting/02-ingress-host-typo.values.yaml
# ~1 minute: Argo CD says Healthy, but the App tab shows 404
kubectl get ingress -n readcycle          # host is readcycle.local - the typo
git log -1 --oneline                      # the commit that did it
git revert --no-edit HEAD && git push     # fix through Git
# ~1 minute: the App tab works again
```

*"Healthy pods are not the same as a working website: probes check pods from inside the
cluster, and this mistake only shows from the outside."*

## If something goes wrong live

- **Pipeline slow:** show the recorded rehearsal instead:
  [before](evidence/screenshots/web-m10-1-before.png),
  [running](evidence/screenshots/web-m10-2-pipeline-running.png),
  [rolled out](evidence/screenshots/m10-live-demo-2-rollout.png),
  [after](evidence/screenshots/web-m10-3-after.png).
- **Laptop cluster stopped:** `docker desktop start`, then `docker start readcycle-control-plane`.
- **Argo CD hasn't picked up the commit yet:** click **Refresh** in the Argo CD UI.
