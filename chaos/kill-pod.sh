#!/usr/bin/env bash
set -euo pipefail

# Kill a random pod in a namespace
# Usage: ./kill-pod.sh <namespace>

NAMESPACE="${1:-default}"

POD=$(kubectl get pods -n "$NAMESPACE" -o jsonpath='{.items[*].metadata.name}' | tr ' ' '\n' | shuf -n1)

if [[ -z "$POD" ]]; then
  echo "No pods found in namespace: $NAMESPACE" >&2
  exit 1
fi

echo "Killing pod: $POD in namespace: $NAMESPACE"
kubectl delete pod "$POD" -n "$NAMESPACE" --grace-period=0 --force
