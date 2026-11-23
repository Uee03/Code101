docker run --name code101-verify-01-hello hello-world:latest
docker ps -a --filter name=code101-verify-01-hello --format "{{.Names}}: {{.State}}"
docker logs code101-verify-01-hello
docker rm code101-verify-01-hello
