#!/bin/bash
# check-demo-sync.sh
# Verify that visual tokens (shadow-*, bg-*) used in static state sections
# also appear in the interactive demo section.
#
# Automatically excludes tokens from Disabled/Selected-Disabled state blocks.
# To manually exclude a token, add a comment in the states section:
#   <!-- demo-skip: bg-base-200 bg-base-300 -->
#
# Usage: ./scripts/check-demo-sync.sh [file.html ...]
#   No argument = check all previews with a demo section.

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m'

PREVIEW_DIR="$(cd "$(dirname "$0")/../previews" && pwd)"

TOKEN_PATTERN='(shadow-border[-a-z0-9]+|bg-primary|bg-secondary|bg-error|bg-base-200|bg-base-300|bg-base-content\/[0-9]+)'

check_file() {
  local file="$1"
  local basename=$(basename "$file")

  # Skip files without demo section
  if ! grep -q 'id="demo-section"' "$file" 2>/dev/null; then
    return 0
  fi

  # Collect demo-skip tokens
  local skip_tokens=$(grep '<!-- demo-skip:' "$file" 2>/dev/null | sed 's/.*<!-- demo-skip: //; s/ -->.*//' | tr ' ' '\n' | sort -u)

  # Extract demo section tokens (including hover/group-hover variants)
  local demo_tokens=$(sed -n '/id="demo-section"/,/^    <!-- /p' "$file" | \
    grep -oE "(group-hover:|hover:)?${TOKEN_PATTERN}" | \
    sed 's/^group-hover://; s/^hover://' | \
    sort -u)

  # Extract states sections, skipping Disabled/Selected-Disabled blocks
  local states_tokens=$(awk '
    /^    <!-- .*[Ss]tate/ { in_states=1 }
    in_states && /<!-- .*(Disabled|disabled)/ { skip=1 }
    in_states && skip && /<!-- / && !/[Dd]isabled/ { skip=0 }
    in_states && skip && /^        <\/div>/ { skip=0; next }
    in_states && !skip { print }
  ' "$file" | \
    grep -oE "${TOKEN_PATTERN}" | \
    sort -u)

  # Find tokens in states but not in demo (excluding skip list)
  local missing=""
  local has_issue=0
  while IFS= read -r token; do
    [ -z "$token" ] && continue
    # Skip if in demo-skip list
    if echo "$skip_tokens" | grep -qxF "$token" 2>/dev/null; then
      continue
    fi
    if ! echo "$demo_tokens" | grep -qxF "$token"; then
      missing="${missing}  ${token}\n"
      has_issue=1
    fi
  done <<< "$states_tokens"

  if [ $has_issue -eq 1 ]; then
    echo -e "${YELLOW}${basename}${NC}: states tokens not found in demo:"
    echo -e "${RED}${missing}${NC}"
    return 1
  else
    echo -e "${GREEN}${basename}${NC}: OK"
    return 0
  fi
}

exit_code=0

if [ $# -gt 0 ]; then
  for f in "$@"; do
    check_file "$f" || exit_code=1
  done
else
  for f in "$PREVIEW_DIR"/*.html; do
    check_file "$f" || exit_code=1
  done
fi

if [ $exit_code -eq 0 ]; then
  echo -e "\n${GREEN}All demo sections are in sync with their states.${NC}"
else
  echo -e "\n${RED}Some demo sections may be out of sync. Review the above warnings.${NC}"
fi

exit $exit_code
