#!/usr/bin/env bash
# generate-readme.sh — insert ./fetch.sh --help output into README.md *before* the "Copyright" line
set -euo pipefail

README_FILE="README.md"
FETCH="./fetch.sh"

# Checks
[[ -f "$README_FILE" ]] || { echo "Error: $README_FILE not found"; exit 1; }
[[ -x "$FETCH" ]] || { echo "Error: $FETCH is not executable"; exit 1; }
command -v awk >/dev/null || { echo "Error: awk not available"; exit 1; }

# Capture help text
TMP_HELP="$(mktemp)"
TMP_BLOCK="$(mktemp)"
TMP_README="$(mktemp)"
trap 'rm -f "$TMP_HELP" "$TMP_BLOCK" "$TMP_README"' EXIT

"$FETCH" --help > "$TMP_HELP"

# Build block to insert (without any markers)
{
  echo "## Nápověda"
  echo '```text'
  cat "$TMP_HELP"
  echo '```'
  echo
} > "$TMP_BLOCK"

# AWK pipeline:
# 1) Remove any previously inserted "## Nápověda" section (heading + fenced block).
# 2) Insert fresh block right BEFORE the first line that matches /^ *Copyright\b/i/.
awk -v blockfile="$TMP_BLOCK" '
BEGIN {
  IGNORECASE = 1
  skip = 0
  in_code = 0
  inserted = 0
}
function print_block() {
  while ((getline line < blockfile) > 0) print line
  close(blockfile)
}
{
  # ----- 1) Strip existing help block if present -----
  if (!skip && $0 ~ /^##[[:space:]]+Nápověda[[:space:]]*$/) {
    skip = 1
    next
  }
  if (skip) {
    # Consume until we pass the closing code fence ``` (handles nested lines safely)
    if ($0 ~ /^```[[:space:]]*$/) {
      if (in_code == 0) {
        in_code = 1
        next
      } else {
        in_code = 0
        skip = 0
        next
      }
    }
    next
  }

  # ----- 2) Insert before Copyright -----
  # Match lines that start with optional spaces then the word "Copyright"
  if (!inserted && $0 ~ /^[[:space:]]*Copyright([[:space:]]|&|$)/) {
    print_block()
    inserted = 1
  }

  print
}
END {
  # If no Copyright found, append at end to avoid data loss
  if (!inserted) {
    print ""
    print_block()
  }
}
' "$README_FILE" > "$TMP_README"

mv "$TMP_README" "$README_FILE"
echo "README.md updated (help inserted before Copyright)."
