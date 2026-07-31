#!/usr/bin/env bash
# Valida la existencia de archivos dentro de los directorios profesionales.
FULL_POINTS=10
declare -A expected_paths
expected_paths=(
  ["empresa.txt"]="/empresa/empresa.txt /empresa/gerencia/empresa.txt"
  ["politicas.pdf"]="/empresa/gerencia/politicas.pdf"
  ["inventario.xlsx"]="/empresa/administracion/inventario.xlsx"
  ["manual.docx"]="/empresa/soporte/manual.docx"
)
required_dirs=(
  "/empresa"
  "/empresa/administracion"
  "/empresa/gerencia"
  "/empresa/soporte"
)
warnings=()
file_missing=()
for dir in "${required_dirs[@]}"; do
  if [[ -d "$dir" && ! -x "$dir" ]]; then
    warnings+=(" - No se puede acceder a $dir: permiso denegado")
  fi
done
for file in "${!expected_paths[@]}"; do
  ok=false
  for path in ${expected_paths[$file]}; do
    if [[ -f "$path" ]]; then
      ok=true
      break
    fi
  done
  if [[ "$ok" != true ]]; then
    if [[ "$file" == "empresa.txt" ]]; then
      file_missing+=(" - Falta archivo: $file en /empresa/ o /empresa/gerencia/")
    else
      file_missing+=(" - Falta archivo: ${expected_paths[$file]}")
    fi
  fi
done
if (( ${#warnings[@]} == 0 && ${#file_missing[@]} == 0 )); then
  echo "Archivos en la ubicación correcta"
  echo "POINTS:$FULL_POINTS"
  exit 0
fi
for line in "${warnings[@]}"; do
  echo "$line"
done
for line in "${file_missing[@]}"; do
  echo "$line"
done
points=$(( ( ${#expected_paths[@]} - ${#file_missing[@]} ) * FULL_POINTS / ${#expected_paths[@]} ))
if (( points < 0 )); then
  points=0
fi
echo "POINTS:$points"
if (( points == FULL_POINTS )); then
  exit 0
else
  exit 1
fi
