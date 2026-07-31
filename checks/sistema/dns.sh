#!/usr/bin/env bash
EXPECTED="$1"
FULL_POINTS=10
points=0
dns_match=$(grep -E '^nameserver[[:space:]]+' /etc/resolv.conf | awk '{print $2}' | grep -x "$EXPECTED" || true)
if [[ -n "$dns_match" ]]; then
  echo "DNS configurado en /etc/resolv.conf: $EXPECTED"
  points=$FULL_POINTS
else
  echo "DNS $EXPECTED no encontrado en /etc/resolv.conf"
fi
echo "POINTS:$points"
if (( points == FULL_POINTS )); then
  exit 0
else
  exit 1
fi
