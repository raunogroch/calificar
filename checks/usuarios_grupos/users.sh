#!/usr/bin/env bash
# Comprueba que cada usuario exista y que pertenezca al grupo esperado.
# argumentos: usuario:grupo ...
FULL_POINTS=15
total_users=$#
if (( total_users == 0 )); then
  echo "No se proporcionaron usuarios"
  echo "POINTS:0"
  exit 1
fi

checks_per_user=2
total_checks=$((total_users * checks_per_user))
passed_checks=0

for pair in "$@"; do
  user=${pair%%:*}
  req_group=${pair#*:}
  echo "Validando usuario: $user"

  if getent passwd "$user" >/dev/null; then
    echo " - Usuario existe: $user"
    passed_checks=$((passed_checks+1))
  else
    echo " - Usuario NO existe: $user"
    echo ""
    continue
  fi

  if ! getent group "$req_group" >/dev/null; then
    echo " - Grupo esperado NO existe: $req_group"
  elif id -nG "$user" | grep -qw "$req_group"; then
    echo " - Usuario pertenece correctamente al grupo $req_group"
    passed_checks=$((passed_checks+1))
  else
    echo " - Usuario NO pertenece al grupo $req_group"
  fi

  echo ""
done

points=$(( passed_checks * FULL_POINTS / total_checks ))
echo "POINTS:$points"
if (( points == FULL_POINTS )); then
  exit 0
else
  exit 1
fi
