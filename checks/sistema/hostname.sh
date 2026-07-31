#!/usr/bin/env bash
EXPECTED="$1"
FULL_POINTS=15
points=0
actual=$(hostnamectl --static 2>/dev/null || hostname)
if [[ "$actual" == "$EXPECTED" ]]; then
  echo "Hostname correcto: $actual"
  points=$FULL_POINTS
else
  echo "Hostname incorrecto: esperado '$EXPECTED', obtenido '$actual'"
fi
echo "POINTS:$points"
if (( points == FULL_POINTS )); then
  exit 0
else
  exit 1
fi
