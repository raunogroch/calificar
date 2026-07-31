#!/usr/bin/env bash
# Comprueba que cada usuario exista y esté en el grupo asignado.
# argumentos: usuario:grupo ...
FULL_POINTS=15
total_users=$#
if (( total_users == 0 )); then
  echo "No se proporcionaron usuarios"
  echo "POINTS:0"
  exit 1
fi

passed_users=0

for pair in "$@"; do
  user=${pair%%:*}
  req_group=${pair#*:}
  errors=()

  if ! getent passwd "$user" >/dev/null; then
    errors+=(" - Usuario NO existe: $user")
  else
    if ! getent group "$req_group" >/dev/null; then
      errors+=(" - Grupo esperado NO existe: $req_group")
    else
      if id -nG "$user" | grep -qw "$req_group"; then
        :
      else
        errors+=(" - Usuario $user no pertenece al grupo $req_group")
      fi
    fi
  fi

  if (( ${#errors[@]} == 0 )); then
    passed_users=$((passed_users+1))
  else
    echo "Validando usuario: $user (grupo esperado: $req_group)"
    for err in "${errors[@]}"; do
      echo "$err"
    done
    echo
  fi
done

points=$(( passed_users * FULL_POINTS / total_users ))
echo "POINTS:$points"
if (( points == FULL_POINTS )); then
  exit 0
else
  exit 1
fi
