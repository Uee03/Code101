#!/usr/bin/env sh
set -eu

IMAGE="${1:-code101-supply:201}"
trap 'rm -f scan-image.tar' EXIT

echo "== Docker Scout: overview =="
docker scout quickview "$IMAGE"

echo "== Docker Scout: critical and high findings =="
docker scout cves --only-severity critical,high "$IMAGE"

echo "== Trivy: reads a saved tarball, so no Docker socket is mounted =="
docker save "$IMAGE" -o scan-image.tar
docker run --rm -v "$PWD:/work:ro" -v trivy-cache:/root/.cache/ aquasec/trivy:latest image --input /work/scan-image.tar --severity HIGH,CRITICAL --exit-code 1
