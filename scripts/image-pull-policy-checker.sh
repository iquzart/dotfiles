#!/bin/bash

kubectl get deployments -A -o json | jq -r '
.items[] as $d
| (
    ($d.spec.template.spec.containers[]? | . + {type:"container"}),
    ($d.spec.template.spec.initContainers[]? | . + {type:"initContainer"})
  )
| select(.imagePullPolicy == "Always")
| [
    $d.metadata.namespace,
    $d.metadata.name,
    .type,
    .name,
    .imagePullPolicy
  ]
| @csv
' | while IFS= read -r line; do

  namespace=$(echo "$line" | jq -Rr 'split(",")[0] | gsub("^\"|\"$"; "")')
  file="${namespace}-image-pull-policy.csv"

  if [[ ! -f "$file" ]]; then
    echo "NAMESPACE,DEPLOYMENT,CONTAINER_TYPE,CONTAINER_NAME,IMAGE_PULL_POLICY" >"$file"
  fi

  echo "$line" >>"$file"
done
