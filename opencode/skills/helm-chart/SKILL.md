---

name: helm-chart
description: Create helm charts
license: MIT
compatibility: opencode
metadata:
  workflow: github
---


## EXECUTION MODES

### 1. CLARIFICATION MODE

Triggered when required inputs are missing.

### 2. GENERATION MODE

Triggered when all required inputs are available.

---

## INPUT CONTRACT

Required logical inputs:

- workload.type: deployment | statefulset
- ingress.enabled: boolean
- istio.enabled: boolean
- persistence.enabled: boolean
- serviceMonitor.enabled: boolean
- externalSecrets.enabled: boolean

If ANY required field is missing -> CLARIFICATION MODE

---

## CLARIFICATION MODE RULES

Ask ONLY missing critical inputs.
Maximum 5 questions.
No explanations. No prose.

### REQUIRED QUESTIONS TEMPLATE

1. Is this a Deployment or StatefulSet?
2. Do you need persistent storage (PVC)?
3. Do you require Ingress or Istio (or none)?
4. Should ServiceMonitor be enabled for Prometheus?
5. Do you need ExternalSecrets integration?

---

## GENERATION MODE RULES

Once inputs are complete:

- Generate full Helm chart
- Use enterprise Kubernetes standards
- No explanations
- No commentary
- Output strictly structured files in exact order

---

## DEFAULT FALLBACKS (only if user refuses to answer)

- workload.type = deployment
- persistence.enabled = false
- istio.enabled = false
- ingress.enabled = false
- serviceMonitor.enabled = false
- externalSecrets.enabled = false

---

## CHART STRUCTURE (MANDATORY ORDER)

Always generate in EXACT order:

1. Chart.yaml
2. values.yaml
3. values.schema.json
4. templates/_helpers.tpl
5. templates/serviceaccount.yaml
6. templates/workload.yaml
7. templates/service.yaml
8. templates/pvc.yaml (conditional: persistence.enabled)
9. templates/hpa.yaml
10. templates/pdb.yaml
11. templates/networkpolicy.yaml
12. templates/servicemonitor.yaml (conditional: serviceMonitor.enabled)
13. templates/external-secret.yaml (conditional: externalSecrets.enabled)
14. templates/ingress.yaml (conditional: ingress.enabled AND NOT istio.enabled)
15. templates/istio-gateway.yaml (conditional: istio.enabled)
16. templates/istio-virtualservice.yaml (conditional: istio.enabled)
17. templates/istio-destinationrule.yaml (conditional: istio.enabled)
18. templates/NOTES.txt

---

## VALUES.YAML STANDARD (mandatory structure)

```yaml
replicaCount: 2

image:
  repository: ""
  tag: ""
  pullPolicy: IfNotPresent

imagePullSecrets: []
nameOverride: ""
fullnameOverride: ""

serviceAccount:
  create: true
  annotations: {}
  name: ""

podAnnotations: {}

podSecurityContext:
  runAsNonRoot: true
  runAsUser: 1000
  fsGroup: 1000

securityContext:
  allowPrivilegeEscalation: false
  readOnlyRootFilesystem: true
  capabilities:
    drop: ["ALL"]

service:
  type: ClusterIP
  port: 80
  targetPort: 8080

resources:
  requests:
    cpu: 100m
    memory: 128Mi
  limits:
    cpu: 500m
    memory: 256Mi

livenessProbe:
  httpGet:
    path: /healthz
    port: http
  initialDelaySeconds: 10
  periodSeconds: 10

readinessProbe:
  httpGet:
    path: /readyz
    port: http
  initialDelaySeconds: 5
  periodSeconds: 5

startupProbe:
  httpGet:
    path: /healthz
    port: http
  failureThreshold: 30
  periodSeconds: 10

autoscaling:
  enabled: false
  minReplicas: 2
  maxReplicas: 10
  targetCPUUtilizationPercentage: 70

pdb:
  enabled: true
  minAvailable: 1

workload:
  type: deployment

persistence:
  enabled: false
  size: 10Gi
  accessModes:
    - ReadWriteOnce
  storageClass: ""
  mountPath: /data

observability:
  serviceMonitor:
    enabled: false
    interval: 30s
    path: /metrics

istio:
  enabled: false
  gateway:
    hosts: []
  virtualService:
    hosts: []
    http: []

ingress:
  enabled: false
  className: ""
  annotations: {}
  hosts: []
  tls: []

externalSecrets:
  enabled: false
  refreshInterval: 1h
  secretStoreRef:
    name: cluster-secret-store
    kind: ClusterSecretStore
  target:
    name: ""
  data: []

nodeSelector: {}
tolerations: []
affinity:
  podAntiAffinity:
    preferredDuringSchedulingIgnoredDuringExecution:
      - weight: 100
        podAffinityTerm:
          labelSelector:
            matchExpressions:
              - key: app.kubernetes.io/name
                operator: In
                values:
                  - "{{ include \\"<chart>.name\\" . }}"
          topologyKey: kubernetes.io/hostname

topologySpreadConstraints: []
```

---

## SECURITY REQUIREMENTS (non-negotiable on every workload)

Every generated workload MUST include:

```yaml
securityContext:
  runAsNonRoot: true
  runAsUser: 1000
  readOnlyRootFilesystem: true
  allowPrivilegeEscalation: false
  capabilities:
    drop: ["ALL"]

resources:
  requests:
    cpu: 100m
    memory: 128Mi
  limits:
    cpu: 500m
    memory: 256Mi
```

Never omit. Never leave as empty object.

---

## WORKLOAD RULES

### Deployment

- Stateless workload
- replicas controlled by replicaCount and HPA
- Rolling updates: maxUnavailable=0, maxSurge=1
- No volumeClaimTemplates

### StatefulSet

- Stable network identity
- serviceName required (headless service)
- volumeClaimTemplates if persistence.enabled = true
- Ordered startup (podManagementPolicy: OrderedReady)
- updateStrategy: RollingUpdate

---

## PVC RULES

Generate ONLY if persistence.enabled = true.

- StatefulSet: use volumeClaimTemplates (inline in StatefulSet spec)
- Deployment: generate standalone PVC + volumeMounts on container

---

## ISTIO RULES

If istio.enabled = true:

- Generate: Gateway, VirtualService, DestinationRule
- Do NOT generate Ingress resource
- DestinationRule must include circuit breaker and traffic policy

If istio.enabled = false and ingress.enabled = true:

- Generate standard Kubernetes Ingress only

---

## HELPER TEMPLATES (_helpers.tpl mandatory content)

Must define ALL of:

- `<chart>.name` - chart name truncated to 63 chars
- `<chart>.fullname` - release+name, truncated to 63 chars
- `<chart>.chart` - chart name and version label
- `<chart>.labels` - standard labels block
- `<chart>.selectorLabels` - selector labels only
- `<chart>.serviceAccountName` - conditional SA name

---

## NETWORKPOLICY (always generate)

Default-deny ingress except from same namespace and monitoring namespace:

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: {{ include "<chart>.fullname" . }}
spec:
  podSelector:
    matchLabels:
      {{- include "<chart>.selectorLabels" . | nindent 6 }}
  policyTypes:
    - Ingress
    - Egress
  ingress:
    - from:
        - namespaceSelector:
            matchLabels:
              kubernetes.io/metadata.name: monitoring
        - podSelector: {}
  egress:
    - {} # allow all egress by default; tighten per service
```

---

## HPA (always generate, guarded by autoscaling.enabled)

```yaml
{{- if .Values.autoscaling.enabled }}
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
...
{{- end }}
```

---

## PDB (always generate, guarded by pdb.enabled)

```yaml
{{- if .Values.pdb.enabled }}
apiVersion: policy/v1
kind: PodDisruptionBudget
...
{{- end }}
```

---

## OUTPUT FORMAT (STRICT)

```
--- file: Chart.yaml ---
<yaml>

--- file: values.yaml ---
<yaml>

--- file: templates/_helpers.tpl ---
<template>
```

No extra text between files. No explanations. No commentary.

---

## FAIL-SAFE BEHAVIOR

If ambiguity exists:

- Prefer Deployment over StatefulSet
- Disable all optional systems
- Proceed with minimal safe chart

---

## FINAL RULE

- Missing inputs -> ASK QUESTIONS ONLY
- Complete inputs -> GENERATE YAML FILES ONLY
- Never mix modes
