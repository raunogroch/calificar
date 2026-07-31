#!/usr/bin/env bash
# Valida que exista un respaldo comprimido de /empresa y que su contenido coincida con la estructura original.
FULL_POINTS=15
backup_dir="/empresa/backups"
backup_file="$backup_dir/backup_empresa.zip"
restore_dir="/empresa/backups/empresa_restore"
missing=()

if ! command -v zip >/dev/null 2>&1; then
  missing+=(" - No está instalado el paquete zip para comprimir")
fi
if ! command -v unzip >/dev/null 2>&1; then
  missing+=(" - No está instalado el paquete unzip para descomprimir")
fi

if [[ ! -d "/empresa" ]]; then
  missing+=(" - No existe la carpeta /empresa")
fi
if [[ ! -d "$backup_dir" ]]; then
  missing+=(" - No existe la carpeta de respaldos: $backup_dir")
fi
if [[ ! -f "$backup_file" ]]; then
  missing+=(" - No existe el archivo de respaldo: $backup_file")
fi

if (( ${#missing[@]} > 0 )); then
  for line in "${missing[@]}"; do
    echo "$line"
  done
  echo "POINTS:0"
  echo " - El respaldo debe ser creado por el estudiante; este check solo verifica su existencia y contenido."
  exit 1
fi

# Descomprimir para verificar contenido
restore_dir="$(mktemp -d /tmp/empresa_restore.XXXXXX)"
unzip -q "$backup_file" -d "$restore_dir"
if [[ $? -ne 0 ]]; then
  echo " - Error al descomprimir $backup_file"
  echo "POINTS:0"
  rm -rf "$restore_dir"
  exit 1
fi

# Comparar estructura y contenido de directorios, omitiendo /empresa/backups y /empresa/scripts/verificacion.sh
cd /empresa || {
  echo " - No se puede acceder a /empresa"
  echo "POINTS:0"
  rm -rf "$restore_dir"
  exit 1
}
find . \( -path './backups' -o -path './scripts/verificacion.sh' -o -path './desarrollo' \) -prune -o -type f -print | sort > /tmp/empresa_structure.txt

if [[ -d "$restore_dir/empresa" ]]; then
  restore_root="$restore_dir/empresa"
elif [[ -d "$restore_dir" ]]; then
  restore_root="$restore_dir"
else
  echo " - No se pudo localizar la raíz descomprimida de /empresa"
  echo "POINTS:0"
  rm -rf "$restore_dir"
  rm -f /tmp/empresa_structure.txt
  exit 1
fi

cd "$restore_root" || {
  echo " - No se puede acceder a la ruta descomprimida: $restore_root"
  echo "POINTS:0"
  rm -rf "$restore_dir"
  rm -f /tmp/empresa_structure.txt
  exit 1
}
find . \( -path './backups' -o -path './scripts/verificacion.sh' -o -path './desarrollo' \) -prune -o -type f -print | sort > /tmp/empresa_restore_structure.txt

diff_output=$(diff -u /tmp/empresa_structure.txt /tmp/empresa_restore_structure.txt 2>/dev/null)
if [[ -n "$diff_output" ]]; then
  echo " - La estructura descomprimida no coincide con /empresa"
  echo "Diferencias entre /empresa y el respaldo descomprimido:"
  echo "$diff_output"
  echo "POINTS:0"
  rm -rf "$restore_dir"
  rm -f /tmp/empresa_structure.txt /tmp/empresa_restore_structure.txt
  exit 1
fi

# Limpieza
rm -rf "$restore_dir"
rm -f /tmp/empresa_structure.txt /tmp/empresa_restore_structure.txt

echo "Backup verificado correctamente: $backup_file contiene la estructura de /empresa"
echo "POINTS:$FULL_POINTS"
exit 0
