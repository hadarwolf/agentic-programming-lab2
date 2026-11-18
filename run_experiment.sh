#!/usr/bin/env bash
# Lab 2 experiment runner: no-letter-E story, varying word count x CoT on/off.
# Repeats each condition 5 times with a fresh `claude -p` call (no conversation reuse).

set -uo pipefail

MODEL="claude-haiku-4-5"
WORD_COUNTS=(20 50 100)
COT_MODES=("nocot" "cot")
REPEATS=5
OUTDIR="results"
RESULTS_CSV="results.csv"

mkdir -p "$OUTDIR"
echo "word_count,cot,run,verdict,detail" > "$RESULTS_CSV"

make_prompt() {
    local wc="$1"
    local mode="$2"
    if [ "$mode" == "nocot" ]; then
        echo "Write a story that is exactly ${wc} words long. The story must not contain the letter E at all, not even once. Output only the story, nothing else."
    else
        echo "Write a story that is exactly ${wc} words long. The story must not contain the letter E at all, not even once. First think step by step: draft the story, then count the words, then check each word for the letter E, and fix any problems you find. After your reasoning, output the final story on its own line starting with 'FINAL:'"
    fi
}

total=$(( ${#WORD_COUNTS[@]} * ${#COT_MODES[@]} * REPEATS ))
count=0

for wc in "${WORD_COUNTS[@]}"; do
    for mode in "${COT_MODES[@]}"; do
        prompt=$(make_prompt "$wc" "$mode")
        for run in $(seq 1 "$REPEATS"); do
            count=$((count + 1))
            outfile="${OUTDIR}/wc${wc}_${mode}_run${run}.txt"
            echo "[$count/$total] words=$wc mode=$mode run=$run -> $outfile"

            echo "$prompt" | MAX_THINKING_TOKENS=0 claude -p --model "$MODEL" --tools "" \
                --strict-mcp-config --system-prompt "You are a helpful assistant." \
                > "$outfile" 2>/dev/null

            verdict_line=$(python3 check_story.py --target-words "$wc" < "$outfile")
            verdict=$(echo "$verdict_line" | cut -f1)
            detail=$(echo "$verdict_line" | cut -f2-)

            # escape commas/quotes minimally for CSV
            safe_detail=$(echo "$detail" | tr ',' ';' | tr '\n' ' ')
            echo "${wc},${mode},${run},${verdict},\"${safe_detail}\"" >> "$RESULTS_CSV"
        done
    done
done

echo ""
echo "Done. Raw responses in ${OUTDIR}/, scored results in ${RESULTS_CSV}"
echo ""
echo "Quick summary:"
python3 - <<'EOF'
import csv
from collections import defaultdict

totals = defaultdict(lambda: [0, 0])  # (word_count, cot) -> [pass, total]
with open("results.csv") as f:
    for row in csv.DictReader(f):
        key = (row["word_count"], row["cot"])
        totals[key][1] += 1
        if row["verdict"] == "PASS":
            totals[key][0] += 1

for key in sorted(totals):
    passed, total = totals[key]
    print(f"words={key[0]:>4} cot={key[1]:<6} -> {passed}/{total} passed ({100*passed/total:.0f}%)")
EOF
