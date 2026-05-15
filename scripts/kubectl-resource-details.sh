#!/usr/bin/env bash
set -euo pipefail

NAMESPACE="${1:-default}"

cpu_to_millicores() {
  local v="${1:-}"
  [[ -z "$v" ]] && { echo 0; return; }
  if [[ "$v" == *m ]]; then
    echo "${v%m}"
  else
    awk -v n="$v" 'BEGIN { printf "%d", (n * 1000) }'
  fi
}

mem_to_mib() {
  local v="${1:-}"
  [[ -z "$v" ]] && { echo 0; return; }
  case "$v" in
    *Ki) awk -v n="${v%Ki}" 'BEGIN { printf "%d", (n / 1024) }' ;;
    *Mi) echo "${v%Mi}" ;;
    *Gi) awk -v n="${v%Gi}" 'BEGIN { printf "%d", (n * 1024) }' ;;
    *Ti) awk -v n="${v%Ti}" 'BEGIN { printf "%d", (n * 1024 * 1024) }' ;;
    *) echo 0 ;;
  esac
}

sum_cpu_list_to_millicores() {
  local sum=0 item
  for item in $1; do
    [[ -z "$item" ]] && continue
    sum=$((sum + $(cpu_to_millicores "$item")))
  done
  echo "$sum"
}

sum_mem_list_to_mib() {
  local sum=0 item
  for item in $1; do
    [[ -z "$item" ]] && continue
    sum=$((sum + $(mem_to_mib "$item")))
  done
  echo "$sum"
}

round_up() {
  local n="$1"
  local step="${2:-10}"
  echo $(( ((n + step - 1) / step) * step ))
}

to_int() {
  local v="${1:-}"
  if [[ "$v" =~ ^[0-9]+$ ]]; then
    echo "$v"
  else
    echo 0
  fi
}

echo "=== NAMESPACE: ${NAMESPACE} ==="
echo ""

echo "=== USAGE (PODS) ==="
kubectl top pods -n "$NAMESPACE" || true

echo ""
echo "=== REQUESTS / LIMITS (DEPLOYMENTS) ==="
kubectl get deploy -n "$NAMESPACE" \
  -o custom-columns='DEPLOYMENT:.metadata.name,\
CPU_REQ:.spec.template.spec.containers[*].resources.requests.cpu,\
CPU_LIM:.spec.template.spec.containers[*].resources.limits.cpu,\
MEM_REQ:.spec.template.spec.containers[*].resources.requests.memory,\
MEM_LIM:.spec.template.spec.containers[*].resources.limits.memory'

echo ""
echo "=== HPA DETAILS ==="
kubectl get hpa -n "$NAMESPACE" || true

echo ""
echo "=== RECOMMENDATIONS (BASED ON CURRENT SNAPSHOT) ==="
printf "%-28s %-11s %-11s %-11s %-11s %-11s %-11s %s\n" \
  "DEPLOYMENT" "CPU_USE" "CPU_REQ" "CPU_REC" "MEM_USE" "MEM_REQ" "MEM_REC" "HPA_RECOMMENDATION"

deployments=$(kubectl get deploy -n "$NAMESPACE" -o jsonpath='{range .items[*]}{.metadata.name}{"\n"}{end}')
hpa_details="$(kubectl get hpa -n "$NAMESPACE" \
  -o jsonpath='{range .items[*]}{.metadata.name}{"|"}{.spec.scaleTargetRef.kind}{"|"}{.spec.scaleTargetRef.name}{"|"}{.spec.minReplicas}{"|"}{.spec.maxReplicas}{"|"}{.status.currentReplicas}{"\n"}{end}' 2>/dev/null || true)"

while IFS= read -r deploy; do
  [[ -z "$deploy" ]] && continue

  selector=$(kubectl get deploy "$deploy" -n "$NAMESPACE" \
    -o go-template='{{range $k, $v := .spec.selector.matchLabels}}{{printf "%s=%s," $k $v}}{{end}}' | sed 's/,$//')

  cpu_req_raw=$(kubectl get deploy "$deploy" -n "$NAMESPACE" \
    -o jsonpath='{range .spec.template.spec.containers[*]}{.resources.requests.cpu}{" "}{end}')
  mem_req_raw=$(kubectl get deploy "$deploy" -n "$NAMESPACE" \
    -o jsonpath='{range .spec.template.spec.containers[*]}{.resources.requests.memory}{" "}{end}')

  cpu_req_m=$(sum_cpu_list_to_millicores "$cpu_req_raw")
  mem_req_mib=$(sum_mem_list_to_mib "$mem_req_raw")

  top_rows=""
  if [[ -n "$selector" ]]; then
    top_rows=$(kubectl top pod -n "$NAMESPACE" -l "$selector" --no-headers 2>/dev/null || true)
  fi

  cpu_sum=0
  mem_sum=0
  cpu_peak=0
  mem_peak=0
  pod_count=0

  while IFS= read -r row; do
    [[ -z "$row" ]] && continue
    cpu_val=$(awk '{print $2}' <<< "$row")
    mem_val=$(awk '{print $3}' <<< "$row")
    cpu_m=$(cpu_to_millicores "$cpu_val")
    mem_mib=$(mem_to_mib "$mem_val")
    cpu_sum=$((cpu_sum + cpu_m))
    mem_sum=$((mem_sum + mem_mib))
    (( cpu_m > cpu_peak )) && cpu_peak=$cpu_m
    (( mem_mib > mem_peak )) && mem_peak=$mem_mib
    pod_count=$((pod_count + 1))
  done <<< "$top_rows"

  if (( pod_count > 0 )); then
    cpu_avg=$((cpu_sum / pod_count))
    mem_avg=$((mem_sum / pod_count))
  else
    cpu_avg=0
    mem_avg=0
  fi

  if (( cpu_avg > 0 )); then
    cpu_rec=$(round_up $((cpu_avg * 13 / 10)) 10)
  else
    cpu_rec=0
  fi

  if (( mem_avg > 0 )); then
    mem_rec=$(round_up $((mem_avg * 13 / 10)) 16)
  else
    mem_rec=0
  fi

  hpa_line=$(awk -F'|' -v d="$deploy" '$2=="Deployment" && $3==d {print; exit}' <<< "$hpa_details")
  hpa_rec="No change"

  cpu_util=0
  mem_util=0
  (( cpu_req_m > 0 )) && cpu_util=$((cpu_avg * 100 / cpu_req_m))
  (( mem_req_mib > 0 )) && mem_util=$((mem_avg * 100 / mem_req_mib))

  if [[ -z "$hpa_line" ]]; then
    if (( cpu_util >= 70 || mem_util >= 75 )); then
      hpa_rec="Create HPA min=2 max=10 targetCPU=70%"
    fi
  else
    min_r=$(to_int "$(awk -F'|' '{print $4}' <<< "$hpa_line")")
    max_r=$(to_int "$(awk -F'|' '{print $5}' <<< "$hpa_line")")
    cur_r=$(to_int "$(awk -F'|' '{print $6}' <<< "$hpa_line")")

    if (( cpu_util > 90 && cur_r >= max_r )); then
      hpa_rec="Increase maxReplicas (${max_r}->${max_r}+)"
    elif (( cpu_util < 35 && cur_r <= min_r )); then
      hpa_rec="Lower minReplicas or reduce requests"
    fi
  fi

  cpu_use_out="${cpu_avg}m"
  cpu_req_out="${cpu_req_m}m"
  cpu_rec_out="${cpu_rec}m"
  mem_use_out="${mem_avg}Mi"
  mem_req_out="${mem_req_mib}Mi"
  mem_rec_out="${mem_rec}Mi"

  printf "%-28s %-11s %-11s %-11s %-11s %-11s %-11s %s\n" \
    "$deploy" "$cpu_use_out" "$cpu_req_out" "$cpu_rec_out" "$mem_use_out" "$mem_req_out" "$mem_rec_out" "$hpa_rec"
done <<< "$deployments"

echo ""
echo "NOTE: Recommendations are snapshot-based and conservative (avg usage * 1.3)."
echo "      Validate with longer windows (Prometheus/Grafana) before applying in production."
