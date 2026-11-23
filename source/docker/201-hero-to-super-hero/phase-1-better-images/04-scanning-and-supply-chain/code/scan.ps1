param([string]$Image = "code101-supply:201")

Write-Host "== Docker Scout: overview =="
docker scout quickview $Image

Write-Host "== Docker Scout: critical and high findings =="
docker scout cves --only-severity critical,high $Image

Write-Host "== Trivy: reads a saved tarball, so no Docker socket is mounted =="
docker save $Image -o scan-image.tar
try {
    docker run --rm -v "${PWD}:/work:ro" -v trivy-cache:/root/.cache/ aquasec/trivy:latest image --input /work/scan-image.tar --severity HIGH,CRITICAL --exit-code 1
    $trivyExit = $LASTEXITCODE
}
finally {
    Remove-Item scan-image.tar -ErrorAction SilentlyContinue
}
Write-Host "Trivy exit code: $trivyExit (0 = nothing at HIGH or CRITICAL, 1 = findings)"
exit $trivyExit
