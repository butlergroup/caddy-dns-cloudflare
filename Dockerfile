FROM caddy:2-builder-alpine@sha256:8e89605351333ad2cc2f3bcc95275a2ccc427f88914050e86a5fde0fd77a63c4 AS builder

ADD . .

ARG CADDY_VERSION=v2.11.4

RUN go install github.com/caddyserver/xcaddy/cmd/xcaddy@latest && \
    xcaddy build ${CADDY_VERSION} \
    --output /usr/bin/caddy \
    --with "github.com/butlergroup/caddy-dns-cloudflare=."

FROM alpine:latest@sha256:28bd5fe8b56d1bd048e5babf5b10710ebe0bae67db86916198a6eec434943f8b

# added zlib to address CVE-2026-22184
# added openssl to address CVE-2026-2673
# added musl to address CVE-2026-40200
RUN apk update && \
    apk add --no-cache --upgrade \
    zlib \
    openssl \
    musl \
    ca-certificates \
    libcap \
    mailcap

RUN set -eux; \
    mkdir -p \
        /config/caddy \
        /data/caddy \
        /etc/caddy \
        /usr/share/caddy \
    ; \
    wget -O /etc/caddy/Caddyfile "https://github.com/caddyserver/dist/raw/33ae08ff08d168572df2956ed14fbc4949880d94/config/Caddyfile"; \
    wget -O /usr/share/caddy/index.html "https://github.com/caddyserver/dist/raw/33ae08ff08d168572df2956ed14fbc4949880d94/welcome/index.html"

ENV XDG_CONFIG_HOME=/config
ENV XDG_DATA_HOME=/data

COPY --from=builder /usr/bin/caddy /usr/bin/caddy

RUN setcap cap_net_bind_service=+ep /usr/bin/caddy; \
    chmod +x /usr/bin/caddy; \
    caddy version

LABEL org.opencontainers.image.title="Caddy with Cloudflare DNS module"
LABEL org.opencontainers.image.description="Caddy web server image with the butlergroup/caddy-dns-cloudflare DNS provider module baked in"
LABEL org.opencontainers.image.url=https://caddyserver.com
LABEL org.opencontainers.image.documentation=https://caddyserver.com/docs
LABEL org.opencontainers.image.licenses=Apache-2.0
LABEL org.opencontainers.image.source="https://github.com/butlergroup/caddy-dns-cloudflare"

EXPOSE 80
EXPOSE 443
EXPOSE 443/udp
EXPOSE 2019

WORKDIR /srv

CMD ["caddy", "run", "--config", "/etc/caddy/Caddyfile"]
