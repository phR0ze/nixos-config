#!/usr/bin/env bash
export LC_ALL=en_US.UTF-8

input=$(cat)

# Extract fields
MODEL=$(echo "$input" | jq -r '.model.display_name')
COST=$(echo "$input" | jq -r '.cost.total_cost_usd // 0')
PCT=$(echo "$input" | jq -r '.context_window.used_percentage // 0' | cut -d. -f1)
IN_TOKENS=$(echo "$input" | jq -r '.context_window.total_input_tokens // 0')
OUT_TOKENS=$(echo "$input" | jq -r '.context_window.total_output_tokens // 0')
LIMIT_5H=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty')
LIMIT_7D=$(echo "$input" | jq -r '.rate_limits.seven_day.used_percentage // empty')
PROJECT=$(echo "$input" | jq -r '.workspace.project_dir // ""' | xargs basename 2>/dev/null)
HOST=$(hostname -s 2>/dev/null)
# Session name (/rename or auto title), falling back to the short session id
SESSION=$(echo "$input" | jq -r '.session_name // (.session_id // "" | .[0:8])')
EFFORT=$(echo "$input" | jq -r '.effort.level // ""')

# Format values
MODEL_FMT="$MODEL"
[ -n "$EFFORT" ] && MODEL_FMT="${MODEL} (${EFFORT})"
COST_FMT=$(printf '$%.2f' "$COST")
IN_K=$(awk "BEGIN {printf \"%.1fk\", $IN_TOKENS/1000}")
OUT_K=$(awk "BEGIN {printf \"%.1fk\", $OUT_TOKENS/1000}")

# Usage limits (subscription only; absent for API-key billing)
LIMITS_FMT=""
[ -n "$LIMIT_5H" ] && LIMITS_FMT+=$(printf '5h %.0f%%' "$LIMIT_5H")
[ -n "$LIMIT_5H" ] && [ -n "$LIMIT_7D" ] && LIMITS_FMT+=" "
[ -n "$LIMIT_7D" ] && LIMITS_FMT+=$(printf '7d %.0f%%' "$LIMIT_7D")

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

# Left side: model, progress bar, tokens, cost, usage limits
MODEL_COLORED="${TN_PURPLE}[${MODEL}]${RESET}"
[ -n "$EFFORT" ] && MODEL_COLORED+=" ${TN_ORANGE}(${EFFORT})${RESET}"
LEFT="${MODEL_COLORED} ${BAR} ${BAR_COLOR}${PCT}%${RESET}"
LEFT+=" ${TN_COMMENT}|${RESET} ${TN_BLUE}↑${IN_K} ↓${OUT_K}${RESET}"
LEFT+=" ${TN_COMMENT}|${RESET} ${TN_ORANGE}${COST_FMT}${RESET}"
[ -n "$LIMITS_FMT" ] && LEFT+=" ${TN_COMMENT}|${RESET} ${TN_CYAN}${LIMITS_FMT}${RESET}"

# Right side: session, hostname:project
RIGHT=""
[ -n "$SESSION" ] && RIGHT="${TN_PURPLE}${SESSION}${RESET} ${TN_COMMENT}|${RESET} "
RIGHT+="${TN_ORANGE}${HOST}:${RESET}${TN_BLUE}${PROJECT}${RESET}"

# Calculate visible lengths mathematically (all content is ASCII except bar chars)
# Left: MODEL_FMT + " " + bar(BAR_WIDTH) + " " + PCT + "% | ↑" + IN_K + " ↓" + OUT_K + " | " + COST_FMT [+ " | " + LIMITS_FMT]
LEFT_LEN=$(( ${#MODEL_FMT} + 3 + BAR_WIDTH + 1 + ${#PCT} + 1 + 3 + 1 + ${#IN_K} + 2 + ${#OUT_K} + 3 + ${#COST_FMT} ))
[ -n "$LIMITS_FMT" ] && LEFT_LEN=$(( LEFT_LEN + 3 + ${#LIMITS_FMT} ))

# Right: [SESSION + " | "] + HOST + ":" + PROJECT
RIGHT_LEN=$(( ${#HOST} + 1 + ${#PROJECT} ))
[ -n "$SESSION" ] && RIGHT_LEN=$(( RIGHT_LEN + ${#SESSION} + 3 ))

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
