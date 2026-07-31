#!/usr/bin/env bash
# Comprueba que todos los usuarios solicitados existan y luego verifique su grupo.
# argumentos: usuario:grupo ...
FULL_POINTS=15
total_users=$#
if (( total_users == 0 )); then
  echo "No se proporcionaron usuarios"
  echo "POINTS:0"
  exit 1
fi

missing_users=()
valid_users=()
for pair in "$@"; do
  user=${pair%%:*}
  if ! getent passwd "$user" >/dev/null; then
    missing_users+=("$user")
  else
    valid_users+=("$pair")
  fi
done

if (( ${#missing_users[@]} > 0 )); then
  echo "Validando existencia de usuarios:"
  for user in "${missing_users[@]}"; do
    echo " - Usuario NO existe: $user"
  done
  echo
fi

passed_users=0
for pair in "${valid_users[@]}"; do
  user=${pair%%:*}
  req_group=${pair#*:}
  errors=()

  if ! getent group "$req_group" >/dev/null; then
    errors+=(" - Grupo esperado NO existe: $req_group")
  elif ! id -nG "$user" | grep -qw "$req_group"; then
    errors+=(" - Usuario $user no pertenece al grupo $req_group")
  fi

  if (( ${#errors[@]} == 0 )); then
    passed_users=$((passed_users+1))
  else
    echo "Validando grupo para usuario: $user (grupo esperado: $req_group)"
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
