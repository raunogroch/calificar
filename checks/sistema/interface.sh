#!/usr/bin/env bash
IFACE="$1"
FULL_POINTS=15
points=0
ok=0
if ip link show "$IFACE" >/dev/null 2>&1; then
  echo "Interfaz encontrada: $IFACE"
  ok=$((ok+1))
else
  echo "Interfaz no encontrada: $IFACE"
fi

if ip link show "$IFACE" 2>/dev/null | grep -q "UP"; then
  echo "Interfaz $IFACE está UP"
  ok=$((ok+1))
else
  echo "Interfaz $IFACE no está UP"
fi

if (( ok == 2 )); then
  points=$FULL_POINTS
fi

echo "POINTS:$points"
if (( points == FULL_POINTS )); then
  exit 0
else
  exit 1
fi
