#!/usr/bin/env bash
# Comprueba que los usuarios mencionados pertenezcan al grupo principal esperado.
# argumentos: usuario:grupo ...
FULL_POINTS=15
total=$#
if (( total == 0 )); then
  echo "No se proporcionaron pares usuario:grupo"
  echo "POINTS:0"
  exit 1
fi

passed=0
for pair in "$@"; do
  user=${pair%%:*}
  req_group=${pair#*:}
  if ! getent passwd "$user" >/dev/null; then
    echo " - Usuario NO existe: $user"
    continue
  fi
  if ! getent group "$req_group" >/dev/null; then
    echo " - Grupo esperado NO existe: $req_group"
    continue
  fi
  primary_group=$(id -gn "$user")
  if [[ "$primary_group" == "$req_group" ]]; then
    echo " - Usuario $user tiene grupo principal correcto: $primary_group"
    passed=$((passed+1))
  else
    echo " - Usuario $user tiene grupo principal $primary_group, esperado $req_group"
  fi
done

points=$(( passed * FULL_POINTS / total ))
echo "POINTS:$points"
if (( points == FULL_POINTS )); then
  exit 0
else
  exit 1
fi
