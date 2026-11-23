FROM alpine:3.22
ARG VERSION=dev
LABEL org.opencontainers.image.version="${VERSION}"
RUN echo "${VERSION}" > /version.txt
USER 65534:65534
CMD ["cat", "/version.txt"]
