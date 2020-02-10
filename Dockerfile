FROM alpine:3.9

RUN apk add --no-cache git openssh-client

COPY ./mirror.sh /usr/local/bin
COPY ./server.sh /usr/local/bin

RUN mkdir -p /storage; \
    chmod +x /usr/local/bin/mirror.sh; \
    chmod +x /usr/local/bin/server.sh

EXPOSE 8080
VOLUME /storage
WORKDIR /storage

ENTRYPOINT ["/usr/local/bin/server.sh"]
