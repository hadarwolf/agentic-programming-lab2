# 🔎 Finding LLM Failure Modes: the "No Letter E" Story

**Agentic Programming · Lab 2: Find Where the Model Makes Mistakes**
*Hadar Wolf & Nehory*

We asked a model to write a story that is **exactly N words long** and **never uses the letter "e"**. Both rules are easy to check automatically, and they pull against each other: "e" is the most common letter in English, so avoiding it makes it harder to hit an exact word count.

## TL;DR

Chain-of-thought helps the model on easy versions of the task (20 words: **0% → 80%**). On harder versions (50 or 100 words), chain-of-thought still fails, and it also writes "verified ✓" next to answers that break both rules. Instead of admitting failure, it claims a check it never really did.

## Setup

- **Model:** `claude-haiku-4-5`, tools and extended thinking disabled, with a fresh `claude -p` process for every run
- **Conditions:** 20 / 50 / 100 words × with or without chain-of-thought, 5 runs each (30 runs in total)
- **Scoring:** a run passes only if the word count is exact **and** there is no "e". Scored automatically by [`check_story.py`](check_story.py), then checked by hand

## Results

| Words | Chain-of-thought | Pass | Typical failure |
|---:|:---:|:---:|---|
| 20 | no | 0/5 | wrong length, plus a missed "e" |
| 20 | yes | **4/5** | the draft → count → check loop works |
| 50 | no | 0/5 | length off by 2–7 words; "e" missed (e.g. "The") |
| 50 | yes | 0/5 | says "verified ✓" but breaks both rules |
| 100 | no | 0/5 | length off by 3–8 words; "e" missed |
| 100 | yes | 0/5 | says "verified ✓" but breaks both rules |

**Key finding:** the model's own reasoning says "Recount: 50 words ✓" and "No E's found ✓" when both are false. Under length pressure it keeps reaching for "the", the most common word in English.

## Files

| File | What it is |
|---|---|
| [`run_experiment.sh`](run_experiment.sh) | runs every condition 5 times and writes `results/` and `results.csv` |
| [`check_story.py`](check_story.py) | scores one response: exact length and no forbidden letter (`PASS` or `FAIL <reason>`) |
| [`results.csv`](results.csv) | the verdict and the reason for every run |
| [`results/`](results/) | the raw model output for every run |
| [`Lab2_Report.pdf`](Lab2_Report.pdf) | the one-page report ([`.docx`](Lab2_Report.docx)) |

## Reproduce

Requires the [Claude Code](https://claude.com/claude-code) CLI, logged in.

```sh
./run_experiment.sh            # about 30 short claude -p calls
cat results/wc20_cot_run1.txt | python3 check_story.py --target-words 20
```

---

Part of my **Agentic Programming** labs (HUJI, AICODE 67723):
[Lab 1 · CTF Arena](https://github.com/hadarwolf/agentic-programming-lab1) · **Lab 2 · LLM failure modes** · [Lab 3 · Coin Dash with several agents](https://github.com/hadarwolf/agentic-programming-lab3) · [Lab 4 · Traffic monitor spec](https://github.com/hadarwolf/agentic-programming-lab4) · [Lab 5 · Chess: testing new features](https://github.com/hadarwolf/agentic-programming-lab5) · [Lab 6 · Binary search explainer video](https://github.com/hadarwolf/agentic-programming-lab6)
