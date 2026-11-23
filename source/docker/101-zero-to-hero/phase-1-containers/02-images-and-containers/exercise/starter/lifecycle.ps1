docker pull nginx:1.28-alpine
docker run -d --name code101-verify-02-exercise -p 127.0.0.1:8081:80 nginx:1.28-alpine
docker ps --filter name=code101-verify-02-exercise --format "{{.Names}} | {{.State}} | {{.Ports}}"
docker exec code101-verify-02-exercise nginx -v
docker logs --tail 3 code101-verify-02-exercise
docker stop code101-verify-02-exercise
docker rm code101-verify-02-exercise
