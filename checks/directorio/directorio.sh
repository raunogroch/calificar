#!/usr/bin/env bash
# Valida la estructura empresarial bajo /empresa y sus permisos profesionales.
FULL_POINTS=10
paths=(
  /empresa
  /empresa/administracion
  /empresa/desarrollo
  /empresa/soporte
  /empresa/gerencia
  /empresa/backups
  /empresa/scripts
  /empresa/publico
)

missing=()
errors=()
passed=0
checks=0

check_dir() {
  local path="$1"
  if [[ ! -d "$path" ]]; then
    missing+=(" - Falta directorio: $path")
    return 1
  fi
  passed=$((passed+1))
  return 0
}

check_permission() {
  local path="$1"
  local expected_owner="$2"
  local expected_group="$3"
  local expected_mode="$4"
  local description="$5"
  local stat_line
  if [[ ! -d "$path" ]]; then
    return 1
  fi
  stat_line=$(stat -c '%U %G %a' "$path" 2>/dev/null)
  local owner=$(echo "$stat_line" | awk '{print $1}')
  local group=$(echo "$stat_line" | awk '{print $2}')
  local mode=$(echo "$stat_line" | awk '{print $3}')
  local ok=1
  if [[ -n "$expected_owner" && "$owner" != "$expected_owner" ]]; then
    errors+=(" - $path: propietario debe ser $expected_owner, encontrado $owner")
    ok=0
  fi
  if [[ -n "$expected_group" && "$group" != "$expected_group" ]]; then
    errors+=(" - $path: grupo debe ser $expected_group, encontrado $group")
    ok=0
  fi
  if [[ -n "$expected_mode" && "$mode" != "$expected_mode" ]]; then
    errors+=(" - $path: permisos deben ser $expected_mode, encontrados $mode ($description)")
    ok=0
  fi
  if (( ok == 1 )); then
    passed=$((passed+1))
  fi
  return $ok
}

for path in "${paths[@]}"; do
  checks=$((checks+1))
  check_dir "$path"
done

# permisos profesionales
checks=$((checks+1))
check_permission "/empresa/administracion" "root" "administracion" "750" "Solo administracion puede escribir"
checks=$((checks+1))
check_permission "/empresa/desarrollo" "root" "desarrollo" "750" "Solo desarrollo puede modificar"
checks=$((checks+1))
check_permission "/empresa/soporte" "root" "soporte" "750" "Solo soporte puede modificar"
checks=$((checks+1))
check_permission "/empresa/gerencia" "root" "gerencia" "770" "Únicamente gerencia tiene acceso"
checks=$((checks+1))
check_permission "/empresa/publico" "root" "root" "755" "Todos pueden leer"
checks=$((checks+1))
check_permission "/empresa/backups" "root" "root" "700" "Solo root puede acceder"

if (( ${#missing[@]} > 0 )); then
  for line in "${missing[@]}"; do
    echo "$line"
  done
fi
if (( ${#errors[@]} > 0 )); then
  for line in "${errors[@]}"; do
    echo "$line"
  done
fi
points=$(( passed * FULL_POINTS / checks ))
echo "POINTS:$points"
if (( points == FULL_POINTS )); then
  exit 0
else
  exit 1
fi
