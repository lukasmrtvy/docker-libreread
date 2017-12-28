FROM golang:alpine as builder

ENV LIBREREAD_VERSION v1.1.4

RUN apk add --no-cache musl-dev gcc git curl

RUN mkdir -p /go/src/github.com/LibreRead/server  && curl -sSL https://github.com/LibreRead/server/archive/${LIBREREAD_VERSION}.tar.gz | tar xz -C /go/src/github.com/LibreRead/server --strip-components=1 

WORKDIR /go/src/github.com/LibreRead/server

RUN go-wrapper download

RUN go-wrapper install ./cmd/libreread/
 

FROM alpine:3.7

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

RUN apk add --no-cache poppler-utils ca-certificates

VOLUME /libreread

EXPOSE 8080

ENTRYPOINT ["libreread"]