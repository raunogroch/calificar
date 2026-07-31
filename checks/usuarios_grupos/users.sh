#!/usr/bin/env bash
# Comprueba usuarios con requisitos:
# argumentos: usuario:grupo ...
FULL_POINTS=15
total_users=$#
if (( total_users == 0 )); then
  echo "No se proporcionaron usuarios"
  echo "POINTS:0"
  exit 1
fi

total_checks=0
passed_checks=0

for pair in "$@"; do
  user=${pair%%:*}
  req_group=${pair#*:}
  errors=()
  # existe
  if getent passwd "$user" >/dev/null; then
    passed_checks=$((passed_checks+1))
    total_checks=$((total_checks+1))
    pw_field=$(getent passwd "$user")
    IFS=':' read -r uname passwd uid gid gecos home shell <<<"$pw_field"
    # grupo principal
    primary_group=$(getent group "$gid" | awk -F: '{print $1}')
    group_list=$(id -Gn "$user" 2>/dev/null)
    if [[ "$primary_group" == "$req_group" && "$group_list" == "$req_group" ]]; then
      passed_checks=$((passed_checks+1))
    fi
    total_checks=$((total_checks+1))
    if [[ "$primary_group" != "$req_group" ]]; then
      errors+=(" - Grupo principal INCORRECTO: $primary_group (esperado $req_group)")
    elif [[ "$group_list" != "$req_group" ]]; then
      errors+=(" - Tiene grupos adicionales: $group_list (solo se permite $req_group)")
    fi
    # home
    if [[ -d "$home" ]]; then
      passed_checks=$((passed_checks+1))
    fi
    total_checks=$((total_checks+1))
    if [[ ! -d "$home" ]]; then
      errors+=(" - Home NO existe: $home")
    fi
    # shell
    if [[ "$shell" == *"bash" ]]; then
      passed_checks=$((passed_checks+1))
    fi
    total_checks=$((total_checks+1))
    if [[ "$shell" != *"bash" ]]; then
      errors+=(" - Shell NO es bash: $shell")
    fi
  else
    errors+=(" - Usuario NO existe: $user")
    total_checks=$((total_checks+1))
  fi
  if (( ${#errors[@]} > 0 )); then
    echo "Validando usuario: $user (grupo esperado: $req_group)"
    for err in "${errors[@]}"; do
      echo "$err"
    done
    echo
  fi
done

points=$(( passed_checks * FULL_POINTS / total_checks ))
echo "POINTS:$points"
if (( points == FULL_POINTS )); then
  exit 0
else
  exit 1
fi
