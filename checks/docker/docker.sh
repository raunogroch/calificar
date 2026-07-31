#!/usr/bin/env bash
# Valida que exista un contenedor Docker empresa-web con nginx en el puerto 8080 y que sirva el contenido esperado.
FULL_POINTS=15
missing=()

# Verificar que docker esté instalado
if ! command -v docker >/dev/null 2>&1; then
  missing+=(" - Docker no está instalado")
fi

# Verificar contenedor empresa-web
container_name="empresa-web"
if ! docker ps --format '{{.Names}}' | grep -xq "$container_name"; then
  missing+=(" - No existe un contenedor en ejecución llamado $container_name")
else
  image=$(docker inspect --format '{{.Config.Image}}' "$container_name" 2>/dev/null)
  if [[ "$image" != nginx* ]]; then
    missing+=(" - El contenedor $container_name no usa la imagen nginx: $image")
  fi
  port_mapping=$(docker port "$container_name" 80 2>/dev/null)
  if [[ -z "$port_mapping" ]]; then
    missing+=(" - El contenedor $container_name no expone el puerto 80 con mapeo de host")
  elif ! grep -q '8080' <<< "$port_mapping"; then
    missing+=(" - El contenedor $container_name no publica el puerto 8080 en el host")
  fi
fi

# Verificar contenido servido por nginx
if command -v curl >/dev/null 2>&1; then
  page=$(curl -s http://localhost:8080 || true)
  if [[ -n "$page" ]]; then
    for expected in "Servidor AlphaTech" "UPDS"; do
      if ! grep -qF "$expected" <(printf '%s' "$page"); then
        missing+=(" - La página en http://localhost:8080 no contiene: $expected")
      fi
done
  else
    missing+=(" - No se pudo obtener contenido de http://localhost:8080")
  fi
else
  missing+=(" - curl no está instalado para verificar el contenido de la página")
fi

if (( ${#missing[@]} > 0 )); then
  for line in "${missing[@]}"; do
    echo "$line"
  done
  echo "POINTS:0"
  exit 1
fi

echo "Contenedor Docker empresa-web con nginx y contenido correcto encontrado"
echo "POINTS:$FULL_POINTS"
exit 0
