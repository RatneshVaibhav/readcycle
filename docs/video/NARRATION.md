# ReadCycle demo video: narration script

Read each part aloud and save it as its own audio file: `01.m4a` … `08.m4a` (any common format
is fine: m4a, mp3, wav). Separate files make it easy to re-record one part, and each part's
visuals are timed to its own audio. Speak calmly; pauses are fine. Each part shows the
screenshots listed under it.

Recording tips: a quiet room, phone voice-recorder app, phone about 20 cm from your mouth, no
fan noise. Listen to the first file before recording the rest.

---

## 01 — Introduction (~25 s)

> Hi, I'm Ratnesh Vaibhav, and this is my DevOps capstone, ReadCycle.
> ReadCycle is a campus textbook exchange: students list course books they no longer need,
> and other students reserve them.
> The app is deliberately small. The real project is the delivery system around it:
> how one commit travels from my laptop to a monitored Kubernetes cluster, safely and
> automatically.

*Visuals: title card, then the app in the browser.*

## 02 — The application (~30 s)

> The frontend is React, the backend is FastAPI, and the data lives in PostgreSQL, with
> Alembic managing the database schema.
> The API lets you list, search, reserve, update and delete books.
> Eleven automated tests cover the API. They run against an in-memory SQLite database,
> so they never touch real data.

*Visuals: the app; pytest with 11 tests passing.*

## 03 — Docker (~25 s)

> Both parts are containerised. The frontend uses a multi-stage build: Node builds the files,
> and only a small nginx server ships. Both containers run as non-root users.
> With Docker Compose, one command starts the database, the backend and the frontend together.

*Visuals: docker compose up, the containers' user IDs.*

## 04 — CI/CD and security (~45 s)

> Every push to main runs a GitHub Actions pipeline with eleven jobs.
> Tests and the frontend build come first. If they fail, nothing else happens.
> Then the code, the dependencies and the Git history are scanned, and both Docker images are
> built and scanned with Trivy.
> A security gate reads all eight reports and stops the pipeline on any high or critical finding.
> My images have zero. The upstream nginx base image had forty-three fixable vulnerabilities,
> for example CVE-2026-33630 in the c-ares library, so my Dockerfile patches them.
> Finally, the images are pushed to GitHub Container Registry, tagged with the commit ID,
> never "latest".

*Visuals: the green pipeline, the security gate table, the GHCR package page.*

## 05 — Terraform and AWS (~45 s)

> The cloud infrastructure is written in Terraform: a VPC with two public and two private
> subnets, a NAT gateway, and an EKS Kubernetes cluster with a worker node, in Sydney.
> My account only allows that region, and I kept everything on the AWS free plan, with a
> least-privilege user and no credentials in the repository.
> Two real problems came up while building it, and I fixed both: the node group needed an AWS
> service role first, and the storage driver needed its own credentials through EKS Pod
> Identity.
> After testing, terraform destroy removed all twenty-seven resources, so nothing keeps costing
> money.

*Visuals: terraform plan, the AWS Console (VPC, subnets, EKS cluster, node group), terraform destroy.*

## 06 — Kubernetes, Helm and monitoring (~40 s)

> The application is packaged as a Helm chart. It runs two backend and two frontend replicas
> behind ClusterIP services, and PostgreSQL keeps its data on a persistent volume.
> The Ingress sends the slash path to the frontend and slash-API to the backend.
> Under load, the autoscaler grew the backend from two to four pods.
> Prometheus scrapes the backend's metrics, and Grafana shows requests, latency and resources
> in real time.

*Visuals: helm install on EKS, the app through the Ingress, the autoscaler scaling, Prometheus targets, the Grafana dashboard.*

## 07 — GitOps: a change goes live (~35 s)

> Deployments are GitOps. Argo CD watches my GitHub repository and keeps the cluster equal to it.
> Here I change the app's tagline and push. The pipeline runs, and its last job commits the new
> image tag to Git. Argo CD notices and rolls it out.
> In under six minutes the new version is live, and the footer shows the new commit.
> Nobody ran kubectl, and GitHub never needed cluster credentials.

*Visuals: before, the pipeline running, Argo CD synced, after.*

## 08 — Troubleshooting and close (~35 s)

> For the troubleshooting challenge, I broke the system three times through Git, the way a bad
> pull request would.
> The most interesting one was a typo in the Ingress host: every pod and Argo CD said healthy,
> but every user got a 404. Healthy is not the same as working.
> Each fault was investigated through logs and resources, fixed with git revert, and verified.
> Everything, including all the evidence, is in the ReadCycle repository on GitHub.
> Thank you.

*Visuals: the three faults and their fixes, the repository.*
