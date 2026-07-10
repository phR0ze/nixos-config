#!/usr/bin/env bash
export LC_ALL=en_US.UTF-8

input=$(cat)

# Extract fields
MODEL=$(echo "$input" | jq -r '.model.display_name')
COST=$(echo "$input" | jq -r '.cost.total_cost_usd // 0')
PCT=$(echo "$input" | jq -r '.context_window.used_percentage // 0' | cut -d. -f1)
IN_TOKENS=$(echo "$input" | jq -r '.context_window.total_input_tokens // 0')
OUT_TOKENS=$(echo "$input" | jq -r '.context_window.total_output_tokens // 0')
DURATION_MS=$(echo "$input" | jq -r '.cost.total_duration_ms // 0' | cut -d. -f1)
LINES_ADD=$(echo "$input" | jq -r '.cost.total_lines_added // 0')
LINES_REM=$(echo "$input" | jq -r '.cost.total_lines_removed // 0')
PROJECT=$(echo "$input" | jq -r '.workspace.project_dir // ""' | xargs basename 2>/dev/null)
STYLE=$(echo "$input" | jq -r '.output_style.name // ""')

# Format values
COST_FMT=$(printf '$%.2f' "$COST")
IN_K=$(awk "BEGIN {printf \"%.1fk\", $IN_TOKENS/1000}")
OUT_K=$(awk "BEGIN {printf \"%.1fk\", $OUT_TOKENS/1000}")

DURATION_S=$((DURATION_MS / 1000))
DURATION_M=$((DURATION_S / 60))
DURATION_RS=$((DURATION_S % 60))
if [ "$DURATION_M" -gt 0 ]; then
  DUR_FMT="${DURATION_M}m ${DURATION_RS}s"
else
  DUR_FMT="${DURATION_RS}s"
fi

# Tokyo Night colors (truecolor)
RESET=$'\e[0m'
TN_BLUE=$'\e[38;2;122;162;247m'       # #7aa2f7
TN_CYAN=$'\e[38;2;125;207;255m'       # #7dcfff
TN_GREEN=$'\e[38;2;158;206;106m'      # #9ece6a
TN_YELLOW=$'\e[38;2;224;175;104m'     # #e0af68
TN_ORANGE=$'\e[38;2;255;158;100m'     # #ff9e64
TN_RED=$'\e[38;2;247;118;142m'        # #f7768e
TN_PURPLE=$'\e[38;2;187;154;247m'     # #bb9af7
TN_COMMENT=$'\e[38;2;86;95;137m'      # #565f89

# Bar color based on context usage
if [ "$PCT" -ge 80 ]; then
  BAR_COLOR=$TN_RED
elif [ "$PCT" -ge 60 ]; then
  BAR_COLOR=$TN_YELLOW
else
  BAR_COLOR=$TN_GREEN
fi

# Build progress bar
BAR_WIDTH=20
FILLED=$((PCT * BAR_WIDTH / 100))
EMPTY=$((BAR_WIDTH - FILLED))

FILLED_BAR=""
EMPTY_BAR=""
for ((i=0; i<FILLED; i++)); do FILLED_BAR+='█'; done
for ((i=0; i<EMPTY; i++)); do EMPTY_BAR+='░'; done

BAR="${BAR_COLOR}${FILLED_BAR}${TN_COMMENT}${EMPTY_BAR}${RESET}"

# Left side: model, progress bar, tokens, cost, duration
LEFT="${TN_PURPLE}[${MODEL}]${RESET} ${BAR} ${BAR_COLOR}${PCT}%${RESET}"
LEFT+=" ${TN_COMMENT}|${RESET} ${TN_BLUE}↑${IN_K} ↓${OUT_K}${RESET}"
LEFT+=" ${TN_COMMENT}|${RESET} ${TN_ORANGE}${COST_FMT}${RESET}"
LEFT+=" ${TN_COMMENT}|${RESET} ${TN_CYAN}${DUR_FMT}${RESET}"

# Right side: project, lines changed, style
RIGHT="${TN_BLUE}${PROJECT}${RESET} ${TN_COMMENT}|${RESET} ${TN_GREEN}+${LINES_ADD}${RESET} ${TN_RED}-${LINES_REM}${RESET}"
if [ -n "$STYLE" ]; then
  STYLE_UPPER=$(echo "$STYLE" | tr '[:lower:]' '[:upper:]')
  RIGHT+=" ${TN_COMMENT}|${RESET} ${TN_PURPLE}${STYLE_UPPER}${RESET}"
fi

# Calculate visible lengths mathematically (all content is ASCII except bar chars)
# Left: MODEL + " " + bar(BAR_WIDTH) + " " + PCT + "% | ↑" + IN_K + " ↓" + OUT_K + " | " + COST_FMT + " | " + DUR_FMT
LEFT_LEN=$(( ${#MODEL} + 3 + BAR_WIDTH + 1 + ${#PCT} + 1 + 3 + 1 + ${#IN_K} + 2 + ${#OUT_K} + 3 + ${#COST_FMT} + 3 + ${#DUR_FMT} ))

# Right: PROJECT + " | +" + LINES_ADD + " -" + LINES_REM [+ " | " + STYLE]
RIGHT_LEN=$(( ${#PROJECT} + 3 + 1 + ${#LINES_ADD} + 2 + ${#LINES_REM} ))
[ -n "$STYLE" ] && RIGHT_LEN=$(( RIGHT_LEN + 3 + ${#STYLE_UPPER} ))

# Get terminal width — prioritize stty as it reflects actual current size
COLS=$(stty size </dev/tty 2>/dev/null | cut -d' ' -f2)
[ -z "$COLS" ] && COLS="$COLUMNS"
[ -z "$COLS" ] && COLS=$(tput cols 2>/dev/null)
[ -z "$COLS" ] && COLS=200

# Subtract 4 to account for left and right margins added by Claude Code
PAD=$((COLS - LEFT_LEN - RIGHT_LEN - 10))

if [ "$PAD" -gt 0 ]; then
  SPACES=$(printf "%${PAD}s" "")
  echo "${LEFT}${SPACES}${RIGHT}"
else
  echo "${LEFT} ${RIGHT}"
fi
