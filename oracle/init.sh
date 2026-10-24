#!/bin/bash
# Runs inside the Oracle container at startup. Builds wg0.conf from oracle.env.
set -eu

: "${SERVER_PRIVATE_KEY:?SERVER_PRIVATE_KEY missing. Run scripts/gen-keys.sh and put oracle.env next to compose.yml}"
: "${PEER_PUBLIC_KEY:?PEER_PUBLIC_KEY missing in oracle.env}"
: "${PRESHARED_KEY:?PRESHARED_KEY missing in oracle.env}"

HOME_IP="10.13.13.2"
CONF=/config/wg_confs/wg0.conf

mkdir -p /config/wg_confs
umask 077

{
  echo "[Interface]"
  echo "Address = 10.13.13.1/24"
  echo "ListenPort = 51820"
  echo "PrivateKey = ${SERVER_PRIVATE_KEY}"
  echo "PostUp = iptables -A FORWARD -i %i -j ACCEPT; iptables -A FORWARD -o %i -j ACCEPT"
  echo "PostDown = iptables -D FORWARD -i %i -j ACCEPT; iptables -D FORWARD -o %i -j ACCEPT"

  for proto in tcp udp; do
    var="FORWARD_${proto^^}_PORTS"
    for port in $(echo "${!var:-}" | tr ',' ' '); do
      echo "PostUp = iptables -t nat -A PREROUTING -i eth0 -p ${proto} --dport ${port} -j DNAT --to-destination ${HOME_IP}:${port}"
      echo "PostUp = iptables -t nat -A POSTROUTING -o %i -p ${proto} -d ${HOME_IP} --dport ${port} -j MASQUERADE"
      echo "PostDown = iptables -t nat -D PREROUTING -i eth0 -p ${proto} --dport ${port} -j DNAT --to-destination ${HOME_IP}:${port}"
      echo "PostDown = iptables -t nat -D POSTROUTING -o %i -p ${proto} -d ${HOME_IP} --dport ${port} -j MASQUERADE"
    done
  done

  echo ""
  echo "[Peer]"
  echo "PublicKey = ${PEER_PUBLIC_KEY}"
  echo "PresharedKey = ${PRESHARED_KEY}"
  echo "AllowedIPs = ${HOME_IP}/32"
} > "${CONF}"

chmod 600 "${CONF}"
echo "[spearmc-tunnel] wrote ${CONF} (forwarding tcp: ${FORWARD_TCP_PORTS:-none}, udp: ${FORWARD_UDP_PORTS:-none})"
