FROM golang:alpine as builder

ENV LIBREREAD_VERSION 1.2.4

RUN apk add --no-cache musl-dev gcc git curl
RUN mkdir -p /go/src/github.com/LibreRead/server  && curl -sSL https://github.com/LibreRead/server/archive/v${LIBREREAD_VERSION}.tar.gz | tar xz -C /go/src/github.com/LibreRead/server --strip$
WORKDIR /go/src/github.com/LibreRead/server

RUN go get -d -v ./...
RUN go install -v ./...

FROM alpine:3.7

ENV UID 1000
ENV GID 1000
ENV USER htpc
ENV GROUP htpc

ENV LIBREREAD_DOMAIN_ADDRESS=$domain_address
ENV LIBREREAD_SMTP_SERVER=$smtp_server
ENV LIBREREAD_SMTP_PORT=$smtp_port
ENV LIBREREAD_SMTP_ADDRESS=$smtp_address
ENV LIBREREAD_SMTP_PASSWORD=$smtp_password

COPY --from=builder /go/bin/libreread /usr/bin/libreread

ENV LIBREREAD_ASSET_PATH "/usr/local/share/libreread"

WORKDIR /libreread

COPY --from=builder /go/src/github.com/LibreRead/server/templates $LIBREREAD_ASSET_PATH/templates
COPY --from=builder /go/src/github.com/LibreRead/server/static $LIBREREAD_ASSET_PATH/static

RUN addgroup -S ${GROUP} -g ${GID} && adduser -D -S -u ${UID} ${USER} ${GROUP}  && \
    apk add --no-cache poppler-utils ca-certificates && \ 
    chown -R ${USER}:${GROUP} /libreread /usr/local/share/libreread 

VOLUME /libreread

EXPOSE 8080

USER ${USER}

LABEL version=${LIBREREAD_VERSION}
LABEL url=https://github.com/joyread/server


ENTRYPOINT ["libreread"]
