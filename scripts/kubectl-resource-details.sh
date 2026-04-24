echo "=== USAGE ==="
kubectl top pods

echo ""
echo "=== REQUESTS / LIMITS ==="
kubectl get deploy \
  -o custom-columns='DEPLOYMENT:.metadata.name,\
CPU_REQ:.spec.template.spec.containers[*].resources.requests.cpu,\
CPU_LIM:.spec.template.spec.containers[*].resources.limits.cpu,\
MEM_REQ:.spec.template.spec.containers[*].resources.requests.memory,\
MEM_LIM:.spec.template.spec.containers[*].resources.limits.memory'
