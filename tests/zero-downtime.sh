#!/usr/bin/env bash
source "$(dirname "$0")/common.sh"
NEW_TAG="${1:-v1.0.1}"; OUT=results/01-zero-downtime.txt; : > "$OUT"

# Same repository as the running image (e.g. docker.io/preciousdipe/product-service), new tag.
REPO=$(kubectl -n $NS get deploy product-service -o jsonpath='{.spec.template.spec.containers[0].image}'); REPO="${REPO%:*}"

log "Before:"; kubectl -n $NS get deploy product-service -o wide | tee -a "$OUT"
log "Starting k6 (50 req/s, 90 s)"; k6 tests/k6/zero-downtime.js > results/01-k6-output.txt 2>&1 & K6=$!
sleep 15

log "kubectl set image deployment/product-service product-service=${REPO}:${NEW_TAG}"
kubectl -n $NS set image deployment/product-service product-service="${REPO}:${NEW_TAG}" | tee -a "$OUT"
kubectl -n $NS rollout status deployment/product-service --timeout=300s | tee -a "$OUT"
log "After:"; kubectl -n $NS get deploy product-service -o wide | tee -a "$OUT"

wait $K6; RC=$?
grep -E "errors_5xx|http_req_failed|http_reqs" results/01-k6-output.txt | tee -a "$OUT"
[ $RC -eq 0 ] && log "RESULT: PASS - no 5xx or failed requests during the rollout" || log "RESULT: FAIL (k6 exit $RC, see results/01-k6-output.txt)"
log "To run again, first: kubectl -n $NS rollout undo deployment/product-service"
