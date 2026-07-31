#!/usr/bin/env bash
IFACE="$1"
EXPECTED="$2"
FULL_POINTS=15
points=0
actual=$(ip -4 addr show dev "$IFACE" | awk '/inet /{print $2; exit}')
if [[ -n "$actual" ]]; then
  if [[ "$actual" == "$EXPECTED" ]]; then
    echo "IP en $IFACE correcta: $actual"
    points=$FULL_POINTS
  else
    echo "IP en $IFACE incorrecta: esperado '$EXPECTED', obtenido '$actual'"
  fi
else
  echo "No se encontró dirección IPv4 en $IFACE"
fi
echo "POINTS:$points"
if (( points == FULL_POINTS )); then
  exit 0
else
  exit 1
fi
