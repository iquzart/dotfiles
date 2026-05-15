CLUSTER=$(kubectl config current-context)
NS=$(kubectl config view --minify -o jsonpath='{..namespace}')

# fallback to "default" if namespace not set
NS=${NS:-default}

kubectl get deploy -n "$NS" -o json | jq -r '
def imgs(x): (x // []) | map(.image) | join("<br>");

"| Namespace | Deployment | Main Images | Init Images |",
"|---|---|---|---|",
(
  .items[] |
  "| '"$NS"' | \(.metadata.name) | \(imgs(.spec.template.spec.containers)) | \(imgs(.spec.template.spec.initContainers)) |"
)
' >"${CLUSTER}_${NS}.md"
