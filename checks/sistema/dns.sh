#!/usr/bin/env bash
EXPECTED="$1"
FULL_POINTS=10
points=0
NETPLAN_FILE="/etc/netplan/archivo.yaml"

if [[ ! -e "$NETPLAN_FILE" ]]; then
  echo "No existe el archivo de netplan: $NETPLAN_FILE"
  echo "POINTS:0"
  exit 1
fi

if [[ ! -r "$NETPLAN_FILE" ]]; then
  echo "No se puede leer $NETPLAN_FILE. Ejecute como root o corrija permisos."
  echo "POINTS:0"
  exit 1
fi

if python3 - "$EXPECTED" <<'PY'
import re
import sys

expected = sys.argv[1]
filename = '/etc/netplan/archivo.yaml'

try:
    with open(filename, 'r', encoding='utf-8') as f:
        in_nameservers = False
        nameservers_indent = None
        in_addresses = False
        addresses_indent = None

        for line in f:
            line = line.split('#', 1)[0]
            if not line.strip():
                continue

            indent = len(line) - len(line.lstrip(' '))

            if not in_nameservers:
                if re.match(r'^\s*nameservers\s*:\s*$', line):
                    in_nameservers = True
                    nameservers_indent = indent
                    continue
            else:
                if in_addresses:
                    match = re.match(r'^\s*-\s*(\S+)\s*$', line)
                    if match and indent > addresses_indent:
                        if match.group(1) == expected:
                            sys.exit(0)
                        continue
                    if indent <= addresses_indent:
                        in_addresses = False

                inline_match = re.match(r'^\s*addresses\s*:\s*\[([^\]]+)\]', line)
                if inline_match:
                    values = [v.strip() for v in re.split(r',\s*', inline_match.group(1)) if v.strip()]
                    if expected in values:
                        sys.exit(0)
                    continue

                if re.match(r'^\s*addresses\s*:\s*$', line):
                    in_addresses = True
                    addresses_indent = indent
                    continue

                if indent <= nameservers_indent:
                    in_nameservers = False
                    in_addresses = False
except (OSError, UnicodeDecodeError):
    sys.exit(2)
sys.exit(1)
PY
then
  echo "DNS configurado en $NETPLAN_FILE: $EXPECTED"
  points=$FULL_POINTS
else
  echo "DNS $EXPECTED no encontrado en $NETPLAN_FILE"
fi

echo "POINTS:$points"
if (( points == FULL_POINTS )); then
  exit 0
else
  exit 1
fi
