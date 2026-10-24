#!/usr/bin/env bash
# Generates all WireGuard keys once and writes oracle.env + home.env.
# Usage: ./scripts/gen-keys.sh <oracle-public-ip-or-hostname>
set -euo pipefail
cd "$(dirname "$0")/.."

IP="${1:-}"
if [ -z "$IP" ]; then
  echo "Usage: $0 <oracle-public-ip-or-hostname>" >&2
  exit 1
fi

if [ -e oracle.env ] || [ -e home.env ]; then
  echo "oracle.env or home.env already exists. Delete them first if you want new keys." >&2
  exit 1
fi

IMAGE="lscr.io/linuxserver/wireguard:latest"
if command -v wg >/dev/null 2>&1; then
  WG=(wg)
else
  WG=(docker run --rm -i --entrypoint wg "$IMAGE")
fi

SERVER_PRIV=$("${WG[@]}" genkey)
SERVER_PUB=$(printf '%s' "$SERVER_PRIV" | "${WG[@]}" pubkey)
PEER_PRIV=$("${WG[@]}" genkey)
PEER_PUB=$(printf '%s' "$PEER_PRIV" | "${WG[@]}" pubkey)
PSK=$("${WG[@]}" genpsk)

umask 077

cat > oracle.env <<EOF
# Oracle VM settings (secret, do not commit)
SERVER_PRIVATE_KEY=${SERVER_PRIV}
PEER_PUBLIC_KEY=${PEER_PUB}
PRESHARED_KEY=${PSK}
# Ports forwarded through the tunnel to the home machine (comma separated)
FORWARD_TCP_PORTS=25565
FORWARD_UDP_PORTS=
EOF

cat > home.env <<EOF
# Home machine settings (secret, do not commit)
ORACLE_PUBLIC_IP=${IP}
PEER_PRIVATE_KEY=${PEER_PRIV}
SERVER_PUBLIC_KEY=${SERVER_PUB}
PRESHARED_KEY=${PSK}
EOF

echo "Created oracle.env and home.env."
echo "  oracle.env -> copy to the Oracle VM, next to compose.yml"
echo "  home.env   -> keep on the Minecraft machine, next to compose.yml"
