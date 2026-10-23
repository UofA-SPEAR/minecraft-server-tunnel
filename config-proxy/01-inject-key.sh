#!/bin/sh
if [ -f /keys/private.key ]; then
    KEY=$(cat /keys/private.key | tr -d '\r\n')
    sed -i "s|<PRIVATE_KEY>|$KEY|g" /config/wg_confs/wg0.conf
fi
if [ -f /keys/public.key ]; then
    KEY=$(cat /keys/public.key | tr -d '\r\n')
    sed -i "s|<PUBLIC_KEY>|$KEY|g" /config/wg_confs/wg0.conf
fi
