#!/usr/bin/env bash
# Valida Samba, recurso Publico en /empresa/publico, y acceso de maria.
FULL_POINTS=10
missing=()

conf_file="/etc/samba/smb.conf"
service_ok=0

if ! command -v testparm >/dev/null 2>&1; then
  missing+=(" - Samba no está instalado o testparm no está disponible")
fi

if [[ ! -f "$conf_file" ]]; then
  missing+=(" - No existe el archivo de configuración de Samba: $conf_file")
else
  if ! grep -q '^\[Publico\]' "$conf_file"; then
    missing+=(" - smb.conf no define el recurso [Publico]")
  else
    section=$(awk '/^\[Publico\]/{flag=1; next} /^\[/{flag=0} flag{print}' "$conf_file" | sed 's/^[[:space:]]*//')
    if ! grep -qiE '^path[[:space:]]*=' <(printf '%s\n' "$section"); then
      missing+=(" - El recurso Publico no define path=")
    else
      if ! grep -qiE '^path[[:space:]]*=[[:space:]]*/empresa/publico' <(printf '%s\n' "$section"); then
        missing+=(" - El recurso Publico no usa la ruta /empresa/publico")
      fi
    fi

    if ! grep -qiE '^(read only|writable)[[:space:]]*=' <(printf '%s\n' "$section"); then
      missing+=(" - El recurso Publico no define si es lectura/escritura (read only/writable)")
    else
      if ! grep -qiE '^(read only)[[:space:]]*=[[:space:]]*no|^(writable)[[:space:]]*=[[:space:]]*yes' <(printf '%s\n' "$section"); then
        missing+=(" - El recurso Publico no está configurado para permitir lectura y escritura")
      fi
    fi

    if ! grep -qiE '^(guest ok|public)[[:space:]]*=' <(printf '%s\n' "$section"); then
      missing+=(" - El recurso Publico no define guest ok ni public para usuarios autenticados")
    else
      if grep -qiE '^(guest ok|public)[[:space:]]*=[[:space:]]*yes' <(printf '%s\n' "$section"); then
        missing+=(" - El recurso Publico permite acceso anónimo; debe ser solo para usuarios autenticados")
      fi
    fi

    if ! grep -qiE '^(valid users|write list|admin users)[[:space:]]*=' <(printf '%s\n' "$section"); then
      missing+=(" - El recurso Publico no define usuarios válidos para acceder, incluyendo a maria")
    else
      if ! grep -qiE '^(valid users|write list|admin users)[[:space:]]*=[[:space:]]*.*\bmaria\b' <(printf '%s\n' "$section"); then
        missing+=(" - El usuario maria no está listado como usuario autorizado en el recurso Publico")
      fi
    fi
  fi

  # Validación adicional: usuario Maria debe poder entrar solamente a /home/maria con usuario y contraseña
  if grep -q '^\[maria\]' "$conf_file"; then
    home_section=$(awk '/^\[maria\]/{flag=1; next} /^\[/{flag=0} flag{print}' "$conf_file" | sed 's/^[[:space:]]*//')
    if ! grep -qiE '^path[[:space:]]*=[[:space:]]*/home/maria' <(printf '%s\n' "$home_section"); then
      missing+=(" - El recurso [maria] no apunta a /home/maria")
    fi
    if ! grep -qiE '^valid users[[:space:]]*=[[:space:]]*maria' <(printf '%s\n' "$home_section"); then
      missing+=(" - El recurso [maria] debe permitir acceso únicamente a maria")
    fi
    if ! grep -qiE '^guest ok[[:space:]]*=[[:space:]]*no' <(printf '%s\n' "$home_section"); then
      missing+=(" - El recurso [maria] debe requerir autenticación y no permitir acceso de invitado")
    fi
  elif grep -q '^\[homes\]' "$conf_file"; then
    home_section=$(awk '/^\[homes\]/{flag=1; next} /^\[/{flag=0} flag{print}' "$conf_file" | sed 's/^[[:space:]]*//')
    if ! grep -qiE '^valid users[[:space:]]*=[[:space:]]*maria' <(printf '%s\n' "$home_section"); then
      missing+=(" - El recurso [homes] debe permitir acceso únicamente a maria")
    fi
    if ! grep -qiE '^guest ok[[:space:]]*=[[:space:]]*no' <(printf '%s\n' "$home_section"); then
      missing+=(" - El recurso [homes] debe requerir autenticación y no permitir acceso de invitado")
    fi
  else
    missing+=(" - No existe un recurso Samba para /home/maria; se requiere [maria] o [homes] configurado para maria")
  fi
fi

if command -v systemctl >/dev/null 2>&1; then
  if systemctl is-active --quiet smbd || systemctl is-active --quiet samba; then
    service_ok=1
  fi
fi
if (( service_ok == 0 )); then
  if command -v smbstatus >/dev/null 2>&1 && smbstatus >/dev/null 2>&1; then
    service_ok=1
  fi
fi
if (( service_ok == 0 )); then
  missing+=(" - El servicio Samba no está activo")
fi

if ! getent passwd maria >/dev/null 2>&1; then
  missing+=(" - El usuario maria no existe en el sistema")
fi

if command -v pdbedit >/dev/null 2>&1; then
  if ! pdbedit -L 2>/dev/null | grep -q '^maria:'; then
    missing+=(" - El usuario maria no está registrado en la base de datos de Samba")
  fi
fi

if (( ${#missing[@]} > 0 )); then
  for line in "${missing[@]}"; do
    echo "$line"
  done
  echo "POINTS:0"
  exit 1
fi

echo "Samba y el recurso Publico están configurados correctamente"
echo "POINTS:$FULL_POINTS"
exit 0
