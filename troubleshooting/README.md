# Troubleshooting challenge

The final challenge: introduce issues on purpose, then **identify** each one, **investigate**
the logs and resources, find the **root cause**, **fix** it, **verify** the fix and
**document** it.

Here every fault arrives the way real outages usually do: as a commit. The cluster is managed by
Argo CD from this repository, so [`inject.sh`](inject.sh) merges a small "harmless-looking"
change into [`gitops/environments/dev/values.yaml`](../gitops/environments/dev/values.yaml) and
pushes it, exactly like a bad pull request being merged. Argo CD deploys it within about 30
seconds. The fix also goes through Git (`git revert`), never `kubectl edit`.

```bash
troubleshooting/inject.sh troubleshooting/01-wrong-db-user.values.yaml   # break it
git revert --no-edit HEAD && git push                                     # fix it
```

## The faults

| # | Fault file | The change | What breaks | Why |
|---|---|---|---|---|
| F1 | [`01-wrong-db-user.values.yaml`](01-wrong-db-user.values.yaml) | rename the database user to `readcycle_app` | new backend pods crash-loop; old pods keep serving | PostgreSQL only creates the user from `POSTGRES_USER` when its data volume is **empty**; the existing database never gets the new role |
| F2 | [`02-ingress-host-typo.values.yaml`](02-ingress-host-typo.values.yaml) | Ingress host `readcycle.local` | every URL returns 404, yet Argo CD and all probes report **Healthy** | the Ingress rule no longer matches the hostname users type; probes test pods from inside the cluster |
| F3 | [`03-hpa-without-requests.values.yaml`](03-hpa-without-requests.values.yaml) | remove the backend's `resources` | HPA shows `cpu: <unknown>`, Argo CD marks the app **Degraded** | the HPA's target is a percentage of the CPU **request**; without a request there is nothing to divide by |

## Method used for every fault

1. **Symptom:** what does the user see (`curl`), and what does Argo CD say (`argocd app get`)?
2. **Resources:** `kubectl get pods`, `kubectl describe pod`, `kubectl get events --sort-by=.lastTimestamp`.
3. **Logs:** `kubectl logs <pod> --previous` for crashed containers, the ingress controller log for routing.
4. **The wrong object:** compare what is running with what should run (`kubectl get ingress`, `kubectl describe hpa`, the ConfigMap).
5. **The commit:** `git log -p gitops/environments/dev/values.yaml` shows who changed what.
6. **Fix and verify:** `git revert`, wait for Argo CD to sync, repeat the check from step 1.

## Evidence

The full investigation of each fault, with screenshots, is being recorded in this repository and
will be linked here. The same three faults were first worked through in the
[Session 21 lab write-up](https://github.com/RatneshVaibhav/Devops-Assignments/blob/main/session-21-final-devops-project/final-devops-project/troubleshooting/README.md),
together with five real incidents that happened on the laptop cluster.
