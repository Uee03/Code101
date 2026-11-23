FROM golang:latest
WORKDIR /app
COPY . .
ENV DB_PASSWORD=hunter2
RUN go build -o app .
EXPOSE 8080
CMD ./app
