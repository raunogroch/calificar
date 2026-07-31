#!/usr/bin/env bash
# Valida que docker compose esté instalado, que exista docker-compose.yml o docker-compose.yaml, y que levante dos servicios con la misma página de desarrollo.
FULL_POINTS=15
missing=()

compose_file=""
penalty=0
for candidate in docker-compose.yml docker-compose.yaml; do
  if [[ -f "/empresa/desarrollo/$candidate" ]]; then
    compose_file="/empresa/desarrollo/$candidate"
    break
  fi
done

if ! command -v docker >/dev/null 2>&1; then
  missing+=(" - Docker no está instalado")
else
  if ! docker compose version >/dev/null 2>&1; then
    missing+=(" - Docker Compose no está disponible (use 'docker compose')")
  fi
fi

if [[ -z "$compose_file" ]]; then
  missing+=(" - No existe el archivo docker-compose.yml ni docker-compose.yaml en /empresa/desarrollo")
else
  compose_basename="$(basename "$compose_file")"
  if ! grep -q '^services:' "$compose_file"; then
    missing+=(" - $compose_basename no define la sección services")
  else
    service_names=( $(grep -E '^[[:space:]]{2}[a-zA-Z0-9_-]+:' "$compose_file" | sed 's/^[[:space:]]\{2\}\([^:]*\):.*/\1/') )
    if (( ${#service_names[@]} < 1 )); then
      missing+=(" - $compose_basename debe definir al menos un servicio en la sección services")
    fi
    for svc in "${service_names[@]}"; do
      svc_block=$(awk -v svc="$svc" 'BEGIN{found=0}
        $0 ~ "^  " svc ":" {found=1; next}
        found && $0 ~ "^  [^[:space:]]" {exit}
        found {print}
        END{exit 0}' "$compose_file")
      if ! grep -E '^    image:' <(printf '%s
' "$svc_block"); then
        missing+=(" - El servicio $svc no define image:")
      fi
      if ! grep -E '^    container_name:' <(printf '%s
' "$svc_block"); then
        missing+=(" - El servicio $svc no define container_name:")
      fi
      if ! grep -E '^    ports:' <(printf '%s
' "$svc_block"); then
        missing+=(" - El servicio $svc no define ports:")
      fi
      if ! grep -E '^    volumes:' <(printf '%s
' "$svc_block"); then
        missing+=(" - El servicio $svc no define volumes:")
      fi
    done
  fi
  if grep -q '^version:[[:space:]]*$' "$compose_file"; then
    missing+=(" - $compose_basename contiene 'version:' sin valor")
    penalty=5
  fi
  if ! grep -q '/empresa/desarrollo/index.html' "$compose_file"; then
    missing+=(" - $compose_basename no monta el archivo /empresa/desarrollo/index.html")
  fi
fi

if (( ${#missing[@]} == 0 )); then
  if ! docker compose -f "$compose_file" up -d >/dev/null 2>&1; then
    missing+=(" - Falló docker compose up -d, revise que el archivo $compose_basename sea válido y que los servicios se inicien correctamente")
  else
    running_services=( $(docker compose -f "$compose_file" ps --services 2>/dev/null || true) )
    if (( ${#running_services[@]} < 1 )); then
      missing+=(" - Después de docker compose up -d no hay ningún servicio en ejecución")
    else
      for svc in "${service_names[@]}"; do
        if ! printf '%s
' "${running_services[@]}" | grep -xq "$svc"; then
          missing+=(" - El servicio $svc no está en ejecución después de docker compose up -d")
        fi
      done
    fi

    if command -v curl >/dev/null 2>&1; then
      page_content=""
      for svc in "${service_names[@]}"; do
        port_mapping=$(docker compose -f "$compose_file" port "$svc" 80 2>/dev/null || true)
        if [[ -z "$port_mapping" ]]; then
          missing+=(" - El servicio $svc no publica el puerto 80 al host")
          continue
        fi
        host_port="${port_mapping##*:}"
        if [[ -z "$host_port" ]]; then
          missing+=(" - No se pudo obtener el puerto host para el servicio $svc")
          continue
        fi
        page=$(curl -s "http://localhost:$host_port" || true)
        if [[ -z "$page" ]]; then
          missing+=(" - No se pudo obtener contenido de http://localhost:$host_port para el servicio $svc")
          continue
        fi
        if [[ -z "$page_content" ]]; then
          page_content="$page"
        elif [[ "$page" != "$page_content" ]]; then
          missing+=(" - El servicio $svc no sirve el mismo contenido que las demás instancias")
        fi
      done
    else
      missing+=(" - curl no está instalado para verificar el contenido de los servicios")
    fi
  fi
fi

if (( ${#missing[@]} > 0 )); then
  for line in "${missing[@]}"; do
    echo "$line"
  done
  if (( penalty > 0 )); then
    points=$((FULL_POINTS - penalty))
    if (( points < 0 )); then
      points=0
    fi
    echo "POINTS:$points"
    exit 1
  fi
  echo "POINTS:0"
  exit 1
fi

echo "Docker Compose instalado y ambos servicios se iniciaron correctamente"
echo "POINTS:$FULL_POINTS"
exit 0
