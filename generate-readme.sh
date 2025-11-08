#!/usr/bin/env bash
# generate-readme.sh — vloží výstup ./fetch.sh --help PŘED řádek s "Copyright"
# - Bez HTML komentářů
# - Zachová řádek "Copyright …"
# - Opakované spuštění nahradí starý blok "## Nápověda" (nadpis + fenced code)

set -e

README_FILE="README.md"
FETCH="./fetch.sh"

[[ -f "$README_FILE" ]] || { echo "Error: $README_FILE not found"; exit 1; }
[[ -x "$FETCH" ]] || { echo "Error: $FETCH is not executable"; exit 1; }
command -v awk >/dev/null || { echo "Error: awk not available"; exit 1; }

TMP_HELP="$(mktemp)"
TMP_BLOCK="$(mktemp)"
TMP_OUT="$(mktemp)"
trap 'rm -f "$TMP_HELP" "$TMP_BLOCK" "$TMP_OUT"' EXIT

# Získej nápovědu z fetch.sh
"$FETCH" --help > "$TMP_HELP"

# Sestav vkládaný blok
{
	printf '## Nápověda\n```text\n'
	cat "$TMP_HELP"
	printf '```\n'
} > "$TMP_BLOCK"

# 1) Odstraní existující blok "## Nápověda" až po uzavírací ```
# 2) Vloží nový blok PŘED první řádek, který obsahuje "Copyright" (case-insensitive)
awk -v blockfile="$TMP_BLOCK" '
BEGIN {
	IGNORECASE = 1
	in_help = 0
	seen_open_fence = 0
	inserted = 0
}
function print_block(   line) {
	while ((getline line < blockfile) > 0) print line
	close(blockfile)
}
{
	sub(/\r$/, "")  # ošetření CRLF

	# 1) strip staré nápovědy
	if (!in_help && $0 ~ /^##[[:space:]]+Nápověda[[:space:]]*$/) {
		in_help = 1
		seen_open_fence = 0
		next
	}
	if (in_help) {
		if ($0 ~ /^```[[:space:]]*$/) {
			if (!seen_open_fence) { seen_open_fence = 1; next }
			else { in_help = 0; seen_open_fence = 0; next }
		}
		next
	}

	# 2) vlož blok PŘED copyright řádek a pak vytiskni i samotný řádek
	if (!inserted && $0 ~ /Copyright/) {
		print_block()
		inserted = 1
	}

	print
}
END {
	if (!inserted) {
		print ""
		print_block()
	}
}
' "$README_FILE" > "$TMP_OUT"

mv "$TMP_OUT" "$README_FILE"
echo "README.md aktualizován (nápověda vložena před Copyright)."
