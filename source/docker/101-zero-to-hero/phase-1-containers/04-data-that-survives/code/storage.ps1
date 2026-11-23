docker volume create code101-verify-04-store
docker run --name code101-verify-04-writer --mount type=volume,src=code101-verify-04-store,dst=/data alpine:3.22 sh -c "echo 'Saved recipe' > /data/note.txt"
docker rm code101-verify-04-writer
docker run --name code101-verify-04-reader --mount type=volume,src=code101-verify-04-store,dst=/data alpine:3.22 cat /data/note.txt
docker rm code101-verify-04-reader
docker run --name code101-verify-04-bind --mount "type=bind,src=$($PWD.Path),dst=/host,readonly" alpine:3.22 cat /host/note.txt
docker rm code101-verify-04-bind
docker volume rm code101-verify-04-store
