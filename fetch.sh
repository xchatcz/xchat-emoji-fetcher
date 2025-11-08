#!/usr/bin/env bash
# fetch.sh — stáhne GIF smajlíky CISLO.gif do ./sm/ podle logiky XChat URL
# Volání:
#   ./fetch.sh              -> stáhne 1..9999
#   ./fetch.sh MAX          -> stáhne 1..MAX
#   ./fetch.sh FROM TO      -> stáhne FROM..TO
#   ./fetch.sh --help       -> nápověda

print_help() {
	cat <<'EOF'
Použití:
  ./fetch.sh
  ./fetch.sh MAX
  ./fetch.sh OD DO
  ./fetch.sh --help

Popis:
  Stáhne soubory ve tvaru CISLO.gif do adresáře ./sm/.
  URL vzor: http://x.ximg.cz/images/x4/sm/%1/%2.gif
    - %2 = celé číslo smajlíku (např. 90 → "90.gif")
    - %1 = pokud (%2 mod 100) je 00–09 → použije se JEDNA číslice 0–9
           jinak POSLEDNÍ DVA znaky 10–99

Příklady:
  ./fetch.sh            # 1..9999
  ./fetch.sh 5708       # 1..5708
  ./fetch.sh 50 5708    # 50..5708

Poznámky:
  - Vyžaduje 'wget'
  - Cíl: ./sm/ (vytváří se automaticky)
  - Existující soubory se přeskočí
EOF
}

if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
	print_help
	exit 0
fi

# -------- argumenty --------
re='^[0-9]+$'
case $# in
	0)
		from=1; to=9999
		;;
	1)
		if [[ $1 =~ $re ]]; then from=1; to=$1; else
			echo "Chyba: MAX musí být číslo." >&2; exit 2; fi
		;;
	2)
		if [[ $1 =~ $re && $2 =~ $re ]]; then from=$1; to=$2; else
			echo "Chyba: OD a DO musí být čísla." >&2; exit 2; fi
		;;
	*)
		echo "Chyba: neplatný počet parametrů. ./fetch.sh --help" >&2
		exit 1
		;;
esac

# normalizace
if (( from > to )); then tmp=$from; from=$to; to=$tmp; fi

# -------- příprava --------
if ! command -v wget >/dev/null 2>&1; then
	echo "Chyba: 'wget' není k dispozici." >&2; exit 3
fi

mkdir -p "./sm"
base_url="http://x.ximg.cz/images/x4/sm"

ok=0; fail=0; skipped=0
start_ts=$(date +%s)

# bezpečné ukončení + souhrn i při Ctrl+C
finish() {
	end_ts=$(date +%s)
	elapsed=$(( end_ts - start_ts ))
	hh=$(( elapsed / 3600 ))
	mm=$(( (elapsed / 60) % 60 ))
	ss=$(( elapsed % 60 ))
	echo "Hotovo: ok=${ok}, fail=${fail}, skip=${skipped}"
	printf 'Doba běhu: %02d:%02d:%02d\n' "$hh" "$mm" "$ss"
}
trap finish EXIT

# -------- hlavní smyčka --------
n=$from
while (( n <= to )); do
	last_two=$(( n % 100 ))
	if (( last_two < 10 )); then
		dir="$last_two"                  # '0'..'9'
	else
		printf -v dir "%02d" "$last_two" # '10'..'99'
	fi

	out="sm/${n}.gif"
	url="${base_url}/${dir}/${n}.gif"

	if [[ -s "$out" ]]; then
		echo "skip ${n} (existuje)"
		((skipped++))
		n=$((n+1))
		continue
	fi

	# Stabilnější chování: bez keep-alive, pár retry, rozumný timeout
	if wget -nv --no-http-keep-alive -t 3 --retry-connrefused --timeout=15 -O "$out" "$url"; then
		echo "ok   ${n} → ${out}"
		((ok++))
	else
		echo "fail ${n} (${url})" >&2
		rm -f "$out" || true
		((fail++))
	fi

	# malé zpoždění proti throttlingu
	sleep 0.03
	n=$((n+1))
done

# souhrn vytiskne trap finish
exit 0
