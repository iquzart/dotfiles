#!/bin/bash

NAMESPACE=$1

if [ -z "$NAMESPACE" ]; then
  echo "Usage: $0 <namespace>"
  exit 1
fi

NODE_CPU=4  # node CPU capacity (cores)
NODE_MEM=32 # node memory capacity (GiB)

echo "Namespace: $NAMESPACE"
echo "Node size: ${NODE_CPU} CPU, ${NODE_MEM} GiB RAM"
echo "=============================================================="

# Print per-pod and per-container limits
kubectl get pods -n $NAMESPACE -o json | jq -r '
  .items[] as $pod |
  ($pod.spec.containers | map({
      name: .name,
      cpu_lim: (.resources.limits.cpu // "0"),
      mem_lim: (.resources.limits.memory // "0")
  })) as $containers |

  {
    pod: $pod.metadata.name,
    containers: $containers,
    cpu_lim_total: ($containers
      | map(.cpu_lim | sub("m$";"") | tonumber)
      | add),
    mem_lim_total: ($containers | map(
        if .mem_lim|endswith("Gi") then (.mem_lim|sub("Gi$";"")|tonumber * 1024)
        elif .mem_lim|endswith("Mi") then (.mem_lim|sub("Mi$";"")|tonumber)
        else 0 end
      ) | add)
  }
' | jq -r '
  "Pod: \(.pod)
  -------------------------------------
  CPU Limit Total:   \(.cpu_lim_total / 1000) cores
  Mem Limit Total:   \(.mem_lim_total / 1024) GiB
  Containers:",
  (.containers[] | "  • \(.name)
      CPU Lim: \(.cpu_lim)
      Mem Lim: \(.mem_lim)"),
  "-------------------------------------",
  ""
'

echo "Aggregating TOTAL limits..."
echo "=============================================================="

TOTAL_CPU_LIMIT=$(kubectl get pod -n $NAMESPACE -o json |
  jq '[.items[].spec.containers[].resources.limits.cpu // "0"]
        | map(sub("m$"; "") | tonumber)
        | add')

TOTAL_MEM_LIMIT=$(kubectl get pod -n $NAMESPACE -o json |
  jq '[.items[].spec.containers[].resources.limits.memory // "0"]
        | map(
             if endswith("Gi") then sub("Gi$";"")|tonumber*1024
             elif endswith("Mi") then sub("Mi$";"")|tonumber
             else 0 end
           )
        | add')

CPU_LIMIT_CORES=$(echo "$TOTAL_CPU_LIMIT / 1000" | bc -l)
MEM_LIMIT_GIB=$(echo "$TOTAL_MEM_LIMIT / 1024" | bc -l)

echo "Total CPU LIMITS: $CPU_LIMIT_CORES cores"
echo "Total MEM LIMITS: $MEM_LIMIT_GIB GiB"

# Calculate required nodes (ceil)
NODES_CPU=$(echo "$CPU_LIMIT_CORES / $NODE_CPU" | bc -l)
NODES_MEM=$(echo "$MEM_LIMIT_GIB / $NODE_MEM" | bc -l)

CPU_NODES=$(printf "%.0f" $(echo "$NODES_CPU" | awk '{printf ($1>int($1)?int($1)+1:int($1))}'))
MEM_NODES=$(printf "%.0f" $(echo "$NODES_MEM" | awk '{printf ($1>int($1)?int($1)+1:int($1))}'))

REQUIRED=$((CPU_NODES > MEM_NODES ? CPU_NODES : MEM_NODES))

echo "--------------------------------------------------------------"
echo "Nodes needed based on CPU LIMITS: $CPU_NODES"
echo "Nodes needed based on MEM LIMITS: $MEM_NODES"
echo "🔥 FINAL ESTIMATED NODES REQUIRED: $REQUIRED"
