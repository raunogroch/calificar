#!/usr/bin/env bash
# Valida que exista /empresa/scripts/verificacion.sh y que genere /empresa/backups/reporte.txt
FULL_POINTS=10
script_path="/empresa/scripts/verificacion.sh"
report_path="/empresa/backups/reporte.txt"
missing=()

if [[ ! -f "$script_path" ]]; then
  missing+=(" - No existe el archivo: $script_path")
else
  if [[ ! -x "$script_path" ]]; then
    missing+=(" - El script no tiene permisos de ejecución: $script_path")
  fi
  if ! grep -qE '(/empresa/backups/reporte\.txt|output_file=.*reporte\.txt|>.*reporte\.txt|>>.*reporte\.txt)' "$script_path"; then
    missing+=(" - No se guarda la salida en /empresa/backups/reporte.txt dentro del script")
  fi

  declare -A command_patterns=(
    ["Fecha"]="date"
    ["Hostname"]="hostname"
    ["IP"]="(hostname -I|ip( addr)?|ifconfig)"
    ["Espacio libre"]="df( -h)? /|df( -h)? /empresa?"
    ["Memoria RAM"]="free( -h)?"
    ["Usuarios creados"]="(wc -l < /etc/passwd|awk -F: '.*\\$3 >= 1000'|getent passwd)"
    ["Servicios activos"]="(systemctl list-units --type=service --state=running|service .*(status|start)|ps .*(systemd|init))"
    ["Estado de Docker"]="systemctl is-active docker|docker"
    ["Estado de Samba"]="systemctl is-active smbd|systemctl is-active smb|smbstatus|testparm"
  )
  for label in "${!command_patterns[@]}"; do
    if ! grep -qE "${command_patterns[$label]}" "$script_path"; then
      missing+=(" - El script no consulta $label (falta comando esperado: ${command_patterns[$label]})")
    fi
  done
fi

if [[ ! -f "$report_path" ]]; then
  missing+=(" - No existe el archivo de reporte: $report_path")
elif [[ ! -s "$report_path" ]]; then
  missing+=(" - El archivo de reporte existe pero está vacío: $report_path")
fi

if (( ${#missing[@]} > 0 )); then
  for line in "${missing[@]}"; do
    echo "$line"
  done
  echo "POINTS:0"
  exit 1
fi

echo "El script y el reporte cumplen las validaciones solicitadas"
echo "POINTS:$FULL_POINTS"
exit 0
