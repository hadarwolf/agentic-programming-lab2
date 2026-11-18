#!/usr/bin/env python3
"""
Checks a model's 'no letter E' story response.

Usage:
    cat response.txt | python3 check_story.py --target-words 20

If the response used CoT, the script looks for a line starting with
'FINAL:' and only checks the text after it. If no such marker is
found, it checks the whole response (use this for no-CoT runs).

Prints one line: PASS or FAIL <reason>, and exits 0 on pass, 1 on fail.
"""
import sys
import re
import argparse

def extract_story(text):
    marker = "FINAL:"
    if marker in text:
        return text.split(marker, 1)[1].strip()
    return text.strip()

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--target-words", type=int, required=True)
    parser.add_argument("--forbidden-letter", default="e")
    args = parser.parse_args()

    raw = sys.stdin.read()
    story = extract_story(raw)

    words = story.split()
    word_count = len(words)

    letter = args.forbidden_letter.lower()
    contains_letter = letter in story.lower()

    word_ok = (word_count == args.target_words)
    letter_ok = not contains_letter

    if word_ok and letter_ok:
        print(f"PASS\twords={word_count}\tstory={story!r}")
        sys.exit(0)
    else:
        reasons = []
        if not word_ok:
            reasons.append(f"word_count={word_count} (wanted {args.target_words})")
        if not letter_ok:
            offending = [w for w in words if letter in w.lower()]
            reasons.append(f"contains_letter={letter!r} in {offending[:5]}")
        print(f"FAIL\t{'; '.join(reasons)}\tstory={story!r}")
        sys.exit(1)

if __name__ == "__main__":
    main()
