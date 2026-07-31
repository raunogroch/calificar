#!/usr/bin/env bash
EXPECTED="$1"
FULL_POINTS=10
points=0

NETPLAN_FILES=(/etc/netplan/*.yaml /etc/netplan/*.yml)
existing_files=()
for fn in "${NETPLAN_FILES[@]}"; do
  if [[ -f "$fn" ]]; then
    existing_files+=("$fn")
  fi
done

if [[ ${#existing_files[@]} -eq 0 ]]; then
  echo "No se encontraron archivos YAML en /etc/netplan"
  echo "POINTS:0"
  exit 1
fi

readable=false
for fn in "${existing_files[@]}"; do
  if [[ -r "$fn" ]]; then
    readable=true
    break
  fi
done

if [[ "$readable" != true ]]; then
  echo "No se pueden leer los archivos netplan en /etc/netplan. Ejecute como root o corrija permisos."
  echo "POINTS:0"
  exit 1
fi

if python3 - "$EXPECTED" <<'PY'
import glob
import re
import sys

expected = sys.argv[1]
files = glob.glob('/etc/netplan/*.yaml') + glob.glob('/etc/netplan/*.yml')
for fn in files:
    try:
        with open(fn, 'r', encoding='utf-8') as f:
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
        continue
sys.exit(1)
PY
then
  echo "DNS configurado en netplan: $EXPECTED"
  points=$FULL_POINTS
else
  echo "DNS $EXPECTED no encontrado en los archivos de netplan"
fi

echo "POINTS:$points"
if (( points == FULL_POINTS )); then
  exit 0
else
  exit 1
fi
