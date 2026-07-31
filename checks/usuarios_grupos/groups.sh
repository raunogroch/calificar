#!/usr/bin/env bash
# Comprueba que los grupos pasados como argumentos existen.
FULL_POINTS=15
total=$#
found=0
if (( total == 0 )); then
  echo "No se proporcionaron grupos"
  echo "POINTS:0"
  exit 1
fi
for g in "$@"; do
  if getent group "$g" >/dev/null; then
    echo "Grupo existe: $g"
    found=$((found+1))
  else
    echo "Grupo NO existe: $g"
  fi
done

points=$(( found * FULL_POINTS / total ))
echo "POINTS:$points"
if (( points == FULL_POINTS )); then
  exit 0
else
  exit 1
fi
