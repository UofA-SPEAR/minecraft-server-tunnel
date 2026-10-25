# Userspace WireGuard (wireguard-go) so no kernel module is needed.
# Useful on kernels without WireGuard, e.g. Jetson / Ubuntu 18.04.

# Stage 1: compile wireguard-go (Alpine does not package it)
FROM golang:alpine AS build
RUN apk add --no-cache git
RUN git clone --depth 1 https://github.com/WireGuard/wireguard-go.git /src
WORKDIR /src
RUN CGO_ENABLED=0 go build -o /out/wireguard-go .

# Stage 2: small runtime image
FROM alpine:3.20
RUN apk add --no-cache bash iproute2 iptables wireguard-tools
COPY --from=build /out/wireguard-go /usr/local/bin/wireguard-go
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
