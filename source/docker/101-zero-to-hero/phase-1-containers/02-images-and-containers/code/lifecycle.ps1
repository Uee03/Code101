docker pull nginx:1.28-alpine
docker run -d --name code101-verify-02-web -p 127.0.0.1:8080:80 nginx:1.28-alpine
docker ps --filter name=code101-verify-02-web --format "{{.Names}} | {{.State}} | {{.Ports}}"
docker exec code101-verify-02-web nginx -v
docker logs --tail 3 code101-verify-02-web
docker stop code101-verify-02-web
docker rm code101-verify-02-web
