docker run --name code101-verify-01-exercise hello-world:latest
docker ps -a --filter name=code101-verify-01-exercise --format "{{.Names}}: {{.State}}"
docker logs code101-verify-01-exercise
docker rm code101-verify-01-exercise
