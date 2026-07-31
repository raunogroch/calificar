#!/usr/bin/env bash
# Comprueba que los usuarios mencionados existan.
# argumentos: usuario ...
FULL_POINTS=15
total_users=$#
if (( total_users == 0 )); then
  echo "No se proporcionaron usuarios"
  echo "POINTS:0"
  exit 1
fi

passed_users=0
for user in "$@"; do
  if getent passwd "$user" >/dev/null; then
    echo " - Usuario existe: $user"
    passed_users=$((passed_users+1))
  else
    echo " - Usuario NO existe: $user"
  fi
done

points=$(( passed_users * FULL_POINTS / total_users ))
echo "POINTS:$points"
if (( points == FULL_POINTS )); then
  exit 0
else
  exit 1
fi
