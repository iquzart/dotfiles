#!/bin/bash
#
# Script to split kubectl kubeconfig into separate files for each context
#

mkdir -p ~/.kube/split-configs

echo "🔄 Splitting kubeconfig contexts..."

for context in $(kubectl config get-contexts -o name); do
  kubectl config view --minify --context="$context" --raw >~/.kube/split-configs/kubeconfig-"$context"

  echo "📄 Created: ~/.kube/split-configs/kubeconfig-$context"
done

echo "✅ Completed! All contexts have been saved."
