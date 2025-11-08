#!/usr/bin/env bash
# fetch.sh — stáhne GIF smajlíky CISLO.gif do ./sm/ podle logiky XChat URL
# Použití: ./fetch.sh OD DO
# Nápověda: ./fetch.sh --help

set -euo pipefail

print_help() {
	cat <<'EOF'
Použití:
  ./fetch.sh OD DO

Popis:
  Stáhne všechny soubory ve tvaru CISLO.gif do adresáře ./sm/.
  URL vzor: http://x.ximg.cz/images/x4/sm/%1/%2.gif
    - %2 = celé číslo smajlíku (bez nulování), např. 90 → "90.gif"
    - %1 = pokud poslední dvě číslice (%2 mod 100) jsou 00–09, použije se JEDINÁ číslice 0–9
           jinak se použijí POSLEDNÍ DVA znaky 10–99

Příklady:
  ./fetch.sh 0 99
  ./fetch.sh 1 1234

Poznámky:
  - Vyžaduje 'wget'
  - Cíl: ./sm/ (vytváří se automaticky)
EOF
}

if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
	print_help
	exit 0
fi

if [[ $# -ne 2 ]]; then
	echo "Chyba: očekávám přesně 2 parametry: OD DO" >&2
	echo "Použijte: ./fetch.sh --help" >&2
	exit 1
fi

from="$1"
to="$2"

# Ověření celých nezáporných čísel
re='^[0-9]+$'
if ! [[ $from =~ $re && $to =~ $re ]]; then
	echo "Chyba: OD a DO musí být nezáporná celá čísla." >&2
	exit 2
fi

# Pokud je rozsah obráceně, prohodíme
if (( from > to )); then
	tmp="$from"; from="$to"; to="$tmp"
fi

command -v wget >/dev/null 2>&1 || { echo "Chyba: 'wget' není k dispozici." >&2; exit 3; }

mkdir -p "./sm"

base_url="http://x.ximg.cz/images/x4/sm"

ok=0
fail=0
skipped=0

for (( n=from; n<=to; n++ )); do
	last_two=$(( n % 100 ))
	# %1: 0–9 jako jedna číslice, jinak dvouciferné 10–99
	if (( last_two < 10 )); then
		dir="$last_two"          # '0' až '9'
	else
		# dvouciferné vypisování 10–99
		printf -v dir "%02d" "$last_two"
	fi

	out="sm/${n}.gif"
	url="${base_url}/${dir}/${n}.gif"

	if [[ -s "$out" ]]; then
		echo "skip ${n} (existuje)"
		((skipped++))
		continue
	fi

	# stáhnout s omezením pokusů; při neúspěchu smazat nekompletní soubor
	if wget -q -t 3 --timeout=10 -O "$out" "$url"; then
		echo "ok   ${n} → ${out}"
		((ok++))
	else
		echo "fail ${n} (${url})" >&2
		rm -f "$out" || true
		((fail++))
	fi
done

echo "Hotovo: ok=${ok}, fail=${fail}, skip=${skipped}"
