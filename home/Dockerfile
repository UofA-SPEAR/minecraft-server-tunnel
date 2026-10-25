# Userspace WireGuard (wireguard-go) so no kernel module is needed.
# Useful on kernels without WireGuard, e.g. Jetson / Ubuntu 18.04.
FROM alpine:3.20
RUN apk add --no-cache bash iproute2 iptables wireguard-tools wireguard-go
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
