# Teardown: making sure nothing costs money

## AWS (already done on 16 October 2026)

The EKS session ran from 06:51 to 08:13 and was fully destroyed. The evidence:
[destroy](evidence/screenshots/m7-terraform-destroy_1.png) (27 resources) and
[nothing left](evidence/screenshots/m7-aws-nothing-left.png), checked against AWS itself (no
cluster, VPC, NAT gateway, Elastic IP, instance or volume).

If the infrastructure is ever created again, tear it down in this order. Kubernetes creates
EBS volumes for the PersistentVolumeClaims, and Terraform does not know about them:

```bash
export AWS_PROFILE=readcycle KUBECONFIG=$HOME/.kube/readcycle-eks.yaml
helm uninstall readcycle -n readcycle
helm uninstall kps -n monitoring
helm uninstall ingress-nginx -n ingress-nginx
kubectl delete pvc --all -n readcycle
kubectl delete pvc --all -n monitoring           # their EBS volumes are deleted with them
cd terraform && terraform plan -destroy -out=destroy.tfplan && terraform apply destroy.tfplan

# verify
aws eks list-clusters
aws ec2 describe-vpcs --filters Name=tag:Project,Values=readcycle --query 'length(Vpcs)'
aws ec2 describe-nat-gateways --filter Name=state,Values=pending,available --query 'length(NatGateways)'
aws ec2 describe-volumes --query 'length(Volumes)'
```

## AWS access key: deleted on 16 October 2026

The `readcycle-terraform` user existed only so Terraform could run. Once the infrastructure was
destroyed, its **access key and the user were deleted** in the AWS Console (AWS now answers
`InvalidClientTokenId` for the old key), and the key was removed from the laptop's
`~/.aws/credentials`. Nothing in the project needs it: the pipeline uses only GitHub's own token,
and the live demo runs on the local cluster.

To run Terraform against AWS again, create a new user with
[`terraform/iam-policy-readcycle-terraform.json`](../terraform/iam-policy-readcycle-terraform.json)
and a new access key, and type it in with `aws configure --profile readcycle`. To clean up by
hand after a new run:

1. AWS Console → **IAM** → **Users** → `readcycle-terraform` → **Security credentials** →
   **Access keys** → **Actions → Delete**.
2. Delete the user: **Users** → select `readcycle-terraform` → **Delete**.
3. Delete the policy: **Policies** → `readcycle-terraform` → **Delete** (optional; a policy on its own grants nothing).
4. On the laptop, remove the local copy of the key: delete the `[readcycle]` section from
   `~/.aws/credentials`.

Two AWS-managed service-linked roles (`AWSServiceRoleForAmazonEKS`,
`AWSServiceRoleForAmazonEKSNodegroup`) stay in the account. They are free and harmless.

The account is on the AWS **Free plan**: AWS does not bill the card. Never click **Upgrade
plan**, and never join AWS Organizations; either one moves the account to the paid plan.

## Local machine (optional, after the presentation)

```bash
kind delete cluster --name readcycle    # frees the Docker memory
docker compose down -v                  # if the Compose stack is running
```

The GitHub repository and the public GHCR images stay. Both are free.
