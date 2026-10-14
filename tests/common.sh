set -uo pipefail
NS=app
HOST="microservice-shop.localhost"
GATEWAY="https://$HOST:8443"             
NODE="microservice-kubernetes-application-control-plane"
K6_IMAGE="${K6_IMAGE:-grafana/k6:2.3.0}"
mkdir -p results

# Print with a timestamp and append to the result file ($OUT, set by each script).
log() { echo "[$(date +%H:%M:%S)] $*" | tee -a "$OUT"; }

# curl through the Gateway. -k: the certificate comes from the local CA. --resolve: send $HOST to this machine.
api() { curl -sk --resolve "$HOST:8443:127.0.0.1" -H "Content-Type: application/json" "$@"; }

# Run a k6 script in Docker on the kind network, aimed at the Gateway's HTTPS NodePort.
k6() {
  local ip; ip=$(docker inspect -f '{{.NetworkSettings.Networks.kind.IPAddress}}' "$NODE")
  docker run --rm -i --network kind -e BASE_URL="https://$HOST:30443" -e HOST="$HOST" -e NODE_IP="$ip" "$K6_IMAGE" run - < "$1"
}
