#!/bin/sh
# Start Phoenix with Erlang distribution configured for Clever Cloud Network Groups.
# Finds the WireGuard interface (wg-*) and passes --name to elixir at boot.
# In OTP 26+, Node.start/1 no longer works after VM startup — -name must be set at boot.

WG_IP=$(ip -o addr show | awk '/wg/{split($4,a,"/"); print a[1]; exit}')

if [ -z "$WG_IP" ]; then
  echo "[start] No WireGuard interface found — starting without clustering"
  exec mix phx.server
fi

echo "[start] Erlang node: demo@${WG_IP}"
exec elixir \
  --erl "-kernel inet_dist_listen_min 9000 -kernel inet_dist_listen_max 9010" \
  --name "demo@${WG_IP}" \
  --cookie "${RELEASE_COOKIE}" \
  -S mix phx.server
