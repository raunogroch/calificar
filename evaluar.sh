#!/usr/bin/env bash

if [[ $EUID -ne 0 ]]; then
  if command -v sudo >/dev/null 2>&1 && sudo -n true >/dev/null 2>&1; then
    echo "Reejecutando con sudo para validar archivos y permisos..."
    exec sudo "$0" "$@"
  fi
  echo "Advertencia: no se requieren permisos de root en este entorno de ejecución, pero /empresa puede necesitar acceso privilegiado."
  echo "Ejecute con root si obtiene fallos por permisos en /empresa: sudo ./evaluar.sh"
fi

# Valores esperados
EXPECTED_HOSTNAME="alphaserver"
EXPECTED_IP="192.168.100.10/24"
EXPECTED_GATEWAY="192.168.100.1"
IFACE="enp0s3"

# Puntajes por check (suman 120)
declare -A SCORE
SCORE[hostname]=15
SCORE[interface]=15
SCORE[ip]=15
SCORE[gateway]=15
SCORE[dns]=10
SCORE[groups]=15
SCORE[users]=15
SCORE[directorio]=10
SCORE[archivos]=10

total_score=0
max_score=0

echo "Ejecutando comprobaciones por categoría (muestra puntos y fallos)."

run_check() {
  name="$1"; shift
  # localizar script en checks/*/<name>.sh o checks/<name>.sh
  script=""
  for d in checks/* checks; do
    if [[ -f "$d/$name.sh" ]]; then
      script="$d/$name.sh"
      break
    fi
  done
  if [[ -z "$script" ]]; then
    echo "Script para check '$name' no encontrado"
    printf "%-40s %3s / %3s\n" "$name" "0" "${SCORE[$name]}"
    return
  fi
  max_score=$((max_score+SCORE[$name]))
  out=$($script "$@" 2>&1)
  points=$(echo "$out" | awk -F'POINTS:' '/POINTS:/ {print $2; exit}')
  points=${points:-0}
  total_score=$((total_score+points))
  printf "%-40s %3s / %3s\n" "$name" "$points" "${SCORE[$name]}"
  if (( points < SCORE[$name] )); then
    echo "  Detalles:"
    echo "$out" | sed -n '/POINTS:/!p'
  fi
  echo
}

echo "Sistema---------------------------------- puntos"
run_check hostname "$EXPECTED_HOSTNAME"
run_check interface "$IFACE"
run_check ip "$IFACE" "$EXPECTED_IP"
run_check gateway "$EXPECTED_GATEWAY"
run_check dns "$EXPECTED_DNS"

echo "Usuarios y grupos -------------------------- puntos"
run_check groups administracion desarrollo soporte gerencia
run_check users maria:administracion jose:desarrollo pedro:soporte laura:gerencia

echo "Directorio -------------------------- puntos"
run_check directorio

echo "Archivos -------------------------- puntos"
run_check archivos

echo "Calificación total: $total_score / $max_score"
if (( total_score == max_score )); then
  exit 0
else
  exit 1
fi
