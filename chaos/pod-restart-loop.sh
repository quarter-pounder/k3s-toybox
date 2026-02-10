#!/usr/bin/env bash
set -euo pipefail

# Restart pods in a deployment by deleting random pods in a loop.
# Usage: ./pod-restart-loop.sh <namespace> <label-selector> [interval-seconds]
# Example:
#   ./pod-restart-loop.sh playground app=echo 10

NAMESPACE="${1:-}"
SELECTOR="${2:-}"
INTERVAL="${3:-10}"

if [[ -z "$NAMESPACE" || -z "$SELECTOR" ]]; then
  echo "Usage: $0 <namespace> <label-selector> [interval-seconds]" >&2
  exit 1
fi

if ! kubectl get namespace "$NAMESPACE" >/dev/null 2>&1; then
  echo "Namespace not found: $NAMESPACE" >&2
  exit 1
fi

echo "Pod restart loop"
echo "  Namespace: $NAMESPACE"
echo "  Selector:  $SELECTOR"
echo "  Interval:  ${INTERVAL}s"
echo "Press Ctrl-C to stop."

trap 'echo; echo "Stopping pod restart loop."; exit 0' INT TERM

while true; do
  PODS="$(kubectl get pods -n "$NAMESPACE" -l "$SELECTOR" --field-selector=status.phase=Running -o jsonpath='{.items[*].metadata.name}')"

  if [[ -z "$PODS" ]]; then
    echo "No running pods match selector: $SELECTOR in namespace: $NAMESPACE" >&2
    sleep "$INTERVAL"
    continue
  fi

  POD="$(printf '%s\n' $PODS | shuf -n1)"

  echo "Deleting pod: $POD in namespace: $NAMESPACE"
  kubectl delete pod "$POD" -n "$NAMESPACE" --wait=false || true

  sleep "$INTERVAL"
done

