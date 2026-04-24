---
name: k8s-debugger
description: >
  Full Kubernetes diagnostic playbook. Load this when debugging any cluster
  issue — pod failures, networking, scheduling, RBAC, storage, or HPA problems.
---

# Kubernetes Diagnostic Playbook

## Diagnostic Workflow — Always Follow This Order

1. **Identify scope** — namespace, workload name, cluster context (`kubectl config current-context`)
2. **Check pod state** — `kubectl get pods -n <ns> -o wide`
3. **Describe the failing resource** — `kubectl describe pod <pod> -n <ns>`
4. **Read events** — `kubectl get events -n <ns> --sort-by='.lastTimestamp' | tail -30`
5. **Read logs** — current and previous container
6. **Inspect the workload spec** — deployment/statefulset, resource requests/limits
7. **Check node health** — Ready state, pressure conditions, taints
8. **Check dependencies** — ConfigMaps, Secrets, PVCs, Services, Endpoints

---

## Failure Patterns & Triage

### CrashLoopBackOff

```bash
kubectl logs <pod> -n <ns> --previous        # logs from last crash
kubectl describe pod <pod> -n <ns>           # check exit code, probe failures
```

- Exit code 137 → OOMKilled (memory limit too low)
- Exit code 1 → app crash, check logs
- Exit code 2 → misuse of shell command
- Probe failure → readiness/liveness probe misconfigured or app too slow to start

### OOMKilled

```bash
kubectl top pod <pod> -n <ns>                # current usage
kubectl describe pod <pod> -n <ns> | grep -A5 "Limits\|Requests"
```

- Compare actual usage vs `resources.limits.memory`
- Check for memory leaks via app metrics
- Safe fix: increase `resources.limits.memory` in the deployment spec — show the user the diff, do not apply

### Pending Pod

```bash
kubectl describe pod <pod> -n <ns>           # look at Events section
kubectl get nodes -o wide                    # node status
kubectl describe node <node>                 # check Conditions, Taints, Allocatable
kubectl get pvc -n <ns>                      # if volume related
```

- **Insufficient resources** → nodes don't have enough CPU/memory
- **PVC not bound** → check StorageClass, PV availability
- **Taint/toleration mismatch** → pod needs matching toleration
- **NodeSelector/Affinity mismatch** → labels on nodes don't match pod spec
- **No nodes match** → check `kubectl get nodes --show-labels`

### ImagePullBackOff / ErrImagePull

```bash
kubectl describe pod <pod> -n <ns> | grep -A10 Events
kubectl get secret -n <ns> | grep docker    # check pull secrets exist
```

- Wrong image tag → verify image exists in registry
- Missing `imagePullSecret` → check pod spec and namespace secrets
- Registry auth expired → re-create the secret

### Service Not Reachable

```bash
kubectl get svc <svc> -n <ns> -o yaml       # check selector labels
kubectl get endpoints <svc> -n <ns>         # must have IPs — if empty, selector mismatch
kubectl get pods -n <ns> --show-labels      # compare labels to service selector
kubectl get networkpolicy -n <ns>           # check for blocking policies
```

- Empty Endpoints → selector labels don't match pod labels (case-sensitive, exact match)
- NetworkPolicy blocking → describe the policy, check ingress/egress rules

### RBAC / Forbidden Errors

```bash
# Check if a serviceaccount can perform an action
kubectl auth can-i <verb> <resource> \
  --as=system:serviceaccount:<namespace>:<serviceaccount> \
  -n <namespace>

kubectl get rolebinding,clusterrolebinding -n <ns> \
  -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.subjects}{"\n"}{end}'
```

- Identify which ServiceAccount the pod uses: `kubectl get pod <pod> -n <ns> -o jsonpath='{.spec.serviceAccountName}'`
- Find the RoleBinding → Role → check rules for the missing verb/resource

### HPA Not Scaling

```bash
kubectl describe hpa <hpa> -n <ns>          # check current vs desired replicas, conditions
kubectl top pod -n <ns>                     # verify metrics-server is working
kubectl get apiservice v1beta1.metrics.k8s.io  # check metrics-server API is available
```

- `unknown` metrics → metrics-server not running or pod has no resource requests set
- Stuck at min → actual load is below threshold
- Stuck at max → check `maxReplicas`, node capacity

### Node Not Ready

```bash
kubectl describe node <node>               # check Conditions block
kubectl get pods -n kube-system            # check control plane / daemonsets
```

- DiskPressure → node disk full, check kubelet logs
- MemoryPressure → system-level OOM, not just pod-level
- NetworkPlugin not ready → CNI issue, check CNI daemonset pods

### Helm Release Issues

```bash
helm list -n <ns>                          # check STATUS column
helm status <release> -n <ns>             # detailed status
helm get values <release> -n <ns>         # what values are deployed
helm get manifest <release> -n <ns>       # what k8s resources exist
helm history <release> -n <ns>            # deployment history
```

- `failed` status → check events and pod logs in the namespace
- Values mismatch → compare `helm get values` with expected config

---

## Useful One-Liners

```bash
# All non-running pods across all namespaces
kubectl get pods -A --field-selector=status.phase!=Running | grep -v Completed

# Recent events sorted by time (all namespaces)
kubectl get events -A --sort-by='.lastTimestamp' | tail -40

# Pod resource usage across a namespace
kubectl top pods -n <ns> --sort-by=memory

# Find pods on a specific node
kubectl get pods -A -o wide --field-selector=spec.nodeName=<node>

# Check which pods have no resource limits set
kubectl get pods -n <ns> -o json | \
  jq '.items[] | select(.spec.containers[].resources.limits == null) | .metadata.name'

# Decode a secret for inspection
kubectl get secret <secret> -n <ns> -o jsonpath='{.data}' | \
  jq 'to_entries[] | {key, value: (.value | @base64d)}'

# Check RBAC for a serviceaccount across common verbs
for verb in get list watch create update patch delete; do
  echo -n "$verb: "
  kubectl auth can-i $verb pods \
    --as=system:serviceaccount:<ns>:<sa> -n <ns>
done
```

---

## Safe Read-Only Command Reference

| Goal | Command |
|---|---|
| Pod overview | `kubectl get pods -n <ns> -o wide` |
| Pod details | `kubectl describe pod <pod> -n <ns>` |
| Current logs | `kubectl logs <pod> -n <ns> -c <container>` |
| Previous logs | `kubectl logs <pod> -n <ns> --previous` |
| Follow logs | `kubectl logs -f <pod> -n <ns>` |
| Events | `kubectl get events -n <ns> --sort-by='.lastTimestamp'` |
| Resource usage | `kubectl top pod -n <ns>` |
| Node usage | `kubectl top node` |
| Rollout status | `kubectl rollout status deploy/<name> -n <ns>` |
| Rollout history | `kubectl rollout history deploy/<name> -n <ns>` |
| Diff vs live | `kubectl diff -f <manifest.yaml>` |

---

## Fix Handoff Protocol

When a fix requires a destructive or mutating action, never run it directly.
Output the exact command in a code block and say:

> "This command is ready to run. Please review and execute it yourself, or confirm and I will request bash permission."

This keeps the human in control of all cluster mutations.
