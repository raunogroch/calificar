#!/usr/bin/env bash
# Valida la configuración de UFW para permitir solo SSH, HTTP Docker y Samba.
FULL_POINTS=5
missing=()

if ! command -v ufw >/dev/null 2>&1; then
  missing+=(" - UFW no está instalado")
else
  if [[ $(id -u) -eq 0 ]]; then
    rules=$(ufw status numbered 2>/dev/null || ufw status 2>/dev/null)
  else
    rules=$(sudo -n ufw status numbered 2>/dev/null || sudo -n ufw status 2>/dev/null)
  fi
  if [[ -z "$rules" ]]; then
    missing+=(" - No se puede consultar el estado de UFW")
  else
    if ! grep -E '(^|[[:space:]])22/tcp([[:space:]]|$).*ALLOW' <(echo "$rules"); then
      missing+=(" - UFW no permite SSH en el puerto 22")
    fi
    if ! grep -E '(^|[[:space:]])8080/tcp([[:space:]]|$).*ALLOW' <(echo "$rules"); then
      missing+=(" - UFW no permite HTTP Docker en el puerto 8080")
    fi
    if ! grep -E '(^|[[:space:]])(445/tcp|Samba)([[:space:]]|$).*ALLOW' <(echo "$rules"); then
      missing+=(" - UFW no permite Samba en el puerto 445")
    fi
    other_allows=$(echo "$rules" | grep -E 'ALLOW' | grep -vE '22/tcp|8080/tcp|445/tcp|Samba')
    if [[ -n "$other_allows" ]]; then
      missing+=(" - UFW permite otros puertos además de 22, 8080 y 445: $(echo "$other_allows" | tr '\n' ',' | sed 's/,\s*$/, /')")
    fi
  fi
fi

if (( ${#missing[@]} > 0 )); then
  for line in "${missing[@]}"; do
    echo "$line"
  done
  echo "POINTS:0"
  exit 1
fi

echo "UFW está configurado correctamente para SSH, HTTP Docker y Samba únicamente"
echo "POINTS:$FULL_POINTS"
exit 0
