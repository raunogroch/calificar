#!/usr/bin/env bash
EXPECTED="$1"
FULL_POINTS=15
points=0
actual=$(ip route | awk '/^default/ {print $3; exit}')
if [[ -n "$actual" ]]; then
  if [[ "$actual" == "$EXPECTED" ]]; then
    echo "Gateway por defecto correcto: $actual"
    points=$FULL_POINTS
  else
    echo "Gateway por defecto incorrecto: esperado '$EXPECTED', obtenido '$actual'"
  fi
else
  echo "No se encontró gateway por defecto"
fi
echo "POINTS:$points"
if (( points == FULL_POINTS )); then
  exit 0
else
  exit 1
fi
