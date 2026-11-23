# syntax=docker/dockerfile:1
# TODO 1: name this first stage "build" by adding AS build to the FROM line
FROM node:24-alpine
WORKDIR /app
COPY package.json ./
COPY build.js ./
COPY src ./src
RUN npm run build

# TODO 2: start a second stage named "runtime" from the same small base image
# TODO 3: set ENV NODE_ENV=production and WORKDIR /app, then copy ONLY /app/dist from the build stage
# TODO 4: run as the non-root user "node" (the node image already contains it)
EXPOSE 8080
CMD ["node", "dist/server.js"]
