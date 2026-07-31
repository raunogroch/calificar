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
EXPECTED_DNS="8.8.8.8"
IFACE="enp0s3"

if [[ -n "$1" ]]; then
  LAST_TWO_SEGMENTS="$1"
else
  read -rp "Ingrese los últimos dos segmentos de red (ej. 100.10): " LAST_TWO_SEGMENTS
fi

if [[ ! "$LAST_TWO_SEGMENTS" =~ ^([0-9]{1,3})\.([0-9]{1,3})$ ]]; then
  echo "Formato inválido. Debe ingresarse como segmento3.segmento4, por ejemplo 100.10"
  exit 1
fi
SEGMENT3="${BASH_REMATCH[1]}"
SEGMENT4="${BASH_REMATCH[2]}"
if (( SEGMENT3 < 0 || SEGMENT3 > 255 || SEGMENT4 < 0 || SEGMENT4 > 255 )); then
  echo "Segmentos inválidos. Deben estar entre 0 y 255."
  exit 1
fi
EXPECTED_IP="192.168.${SEGMENT3}.${SEGMENT4}/24"
EXPECTED_GATEWAY="192.168.${SEGMENT3}.1"

# Puntajes por check (suman 100)
declare -A SCORE
SCORE[hostname]=5
SCORE[interface]=10
SCORE[ip]=10
SCORE[gateway]=8
SCORE[dns]=7
SCORE[users_exist]=7
SCORE[users_groups]=8
SCORE[directorio]=9
SCORE[archivos]=8
SCORE[compresion_respaldos]=9
SCORE[script_bash]=8
SCORE[docker]=8
SCORE[docker_compose]=5
SCORE[samba]=2
SCORE[seguridad]=1

total_score=0
max_score=0
TOTAL_POSSIBLE=190
RESULT_NAMES=()
RESULT_POINTS=()
RESULT_MAX=()
ERRORS=()

declare -A AREA_MAP
AREA_MAP[hostname]="sistema"
AREA_MAP[interface]="sistema"
AREA_MAP[ip]="sistema"
AREA_MAP[gateway]="sistema"
AREA_MAP[dns]="sistema"
AREA_MAP[seguridad]="sistema"
AREA_MAP[users_groups]="usuarios y grupos"
AREA_MAP[users_exist]="usuarios y grupos"
AREA_MAP[directorio]="directorios"
AREA_MAP[archivos]="archivos"
AREA_MAP[compresion_respaldos]="compresion y respaldos"
AREA_MAP[script_bash]="script bash"
AREA_MAP[docker]="docker"
AREA_MAP[docker_compose]="docker-compose"
AREA_MAP[samba]="samba"

declare -A AREA_SCORE
AREA_ORDER=()

echo "Ejecutando comprobaciones por categoría..."

echo ""
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
  area="${AREA_MAP[$name]}"
  if [[ -z "$script" ]]; then
    ERRORS+=("[$name] Script no encontrado")
    ERRORS+=("  Max puntos: ${SCORE[$name]}")
    ERRORS+=("")
    AREA_SCORE["$area"]=$((AREA_SCORE["$area"]+0))
    if [[ ! " ${AREA_ORDER[*]} " =~ " $area " ]]; then
      AREA_ORDER+=("$area")
    fi
    return
  fi
  max_score=$((max_score+SCORE[$name]))
  out=$($script "$@" 2>&1)
  points=$(echo "$out" | awk -F'POINTS:' '/POINTS:/ {print $2; exit}')
  points=${points:-0}
  total_score=$((total_score+points))
  AREA_SCORE["$area"]=$((AREA_SCORE["$area"]+points))
  if [[ ! " ${AREA_ORDER[*]} " =~ " $area " ]]; then
    AREA_ORDER+=("$area")
  fi
  if (( points < SCORE[$name] )); then
    ERRORS+=("[$name] $points/${SCORE[$name]}")
    while IFS= read -r line; do
      ERRORS+=("  $line")
    done < <(echo "$out" | sed -n '/POINTS:/!p')
    ERRORS+=("")
  fi
}

run_check hostname "$EXPECTED_HOSTNAME"
run_check interface "$IFACE"
run_check ip "$IFACE" "$EXPECTED_IP"
run_check gateway "$EXPECTED_GATEWAY"
run_check dns "$EXPECTED_DNS"

run_check users_exist maria jose pedro laura
run_check users_groups maria:administracion jose:desarrollo pedro:soporte laura:gerencia

run_check directorio

run_check archivos

run_check compresion_respaldos

run_check script_bash

run_check docker

run_check docker_compose

run_check samba

run_check seguridad

echo ""
timestamp=$(date +"%d_%m_%Y - %H:%M:%S")
output_dir="/empresa/publico"
mkdir -p "$output_dir"
final_conv=$(awk -v s="$total_score" -v T="$TOTAL_POSSIBLE" 'BEGIN{ if(T==0){printf "0.00"} else printf "%.2f", s*100/T }')
if [[ ${#ERRORS[@]} -eq 0 ]]; then
  echo "Felicitaciones, tienes 100/100"
else
  error_file="$output_dir/fallas_${timestamp}.txt"
  printf "%s\n" "ERRORES:" > "$error_file"
  for err in "${ERRORS[@]}"; do
    printf "%s\n" "$err" >> "$error_file"
  done
  echo "Se creó la lista de errores en el directorio: $error_file"
fi
calificacion_file="$output_dir/calificacion_${timestamp}.txt"
{
  echo ""
  echo "Tabla de puntajes por área:"
  printf "%-26s | %12s\n" "Área" "Calificación"
  printf "%-25s-+-%12s\n" "$(printf '%.0s-' {1..25})" "$(printf '%.0s-' {1..12})"
  for area in "${AREA_ORDER[@]}"; do
    max_area=0
    for name in "${!AREA_MAP[@]}"; do
      if [[ "${AREA_MAP[$name]}" == "$area" ]]; then
        max_area=$((max_area+SCORE[$name]))
      fi
    done
    area_points=${AREA_SCORE[$area]:-0}
    converted=$(awk -v a="$area_points" -v T="$TOTAL_POSSIBLE" 'BEGIN{ if(T==0){printf "0.00"} else printf "%.2f", a*100/T }')
    printf "%-25s | %12s\n" "$area" "$converted"
  done
  printf "%-25s-+-%12s\n" "$(printf '%.0s-' {1..25})" "$(printf '%.0s-' {1..12})"
  printf "%-25s | %12s\n" "Calificacion Final" "$final_conv/100"
} | tee "$calificacion_file"

echo
if (( total_score == max_score )); then
  exit 0
else
  exit 1
fi
