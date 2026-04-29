#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.12"
# ///

from __future__ import annotations

import argparse
import math
from dataclasses import dataclass


@dataclass(frozen=True)
class Key:
    letter: str
    x: float
    y: float
    finger: str
    hand: str
    home_x: float
    home_y: float


ROW_OFFSETS = {
    0: 0.0,
    1: 0.5,
    2: 1.0,
}

ROW_LAYOUTS = {
    0: "qwertyuiop",
    1: "asdfghjkl",
    2: "zxcvbnm",
}

FINGER_ASSIGNMENTS = {
    "LP": "qaz",
    "LR": "wsx",
    "LM": "edc",
    "LI": "rfvtgb",
    "RI": "yhnujm",
    "RM": "ik",
    "RR": "ol",
    "RP": "p",
}

FINGER_HOME = {
    "LP": (0.5, 1.0),
    "LR": (1.5, 1.0),
    "LM": (2.5, 1.0),
    "LI": (3.5, 1.0),
    "RI": (6.5, 1.0),
    "RM": (7.5, 1.0),
    "RR": (8.5, 1.0),
    "RP": (9.5, 1.0),
}

FINGER_WEIGHT = {
    "LP": 1.55,
    "LR": 1.28,
    "LM": 1.12,
    "LI": 0.92,
    "RI": 0.92,
    "RM": 1.12,
    "RR": 1.28,
    "RP": 1.55,
}

FINGER_ORDER = {
    "L": {"LP": 0, "LR": 1, "LM": 2, "LI": 3},
    "R": {"RI": 0, "RM": 1, "RR": 2, "RP": 3},
}

KEYBOARD: dict[str, Key] = {}
for row, letters in ROW_LAYOUTS.items():
    offset = ROW_OFFSETS[row]
    for column, letter in enumerate(letters):
        x = offset + column
        y = float(row)
        finger = next(
            finger_name
            for finger_name, assigned in FINGER_ASSIGNMENTS.items()
            if letter in assigned
        )
        hand = "L" if finger.startswith("L") else "R"
        home_x, home_y = FINGER_HOME[finger]
        KEYBOARD[letter] = Key(
            letter=letter,
            x=x,
            y=y,
            finger=finger,
            hand=hand,
            home_x=home_x,
            home_y=home_y,
        )

KEYBOARD["-"] = Key(
    letter="-",
    x=10.0,
    y=-1.0,
    finger="RP",
    hand="R",
    home_x=FINGER_HOME["RP"][0],
    home_y=FINGER_HOME["RP"][1],
)

for column, digit in enumerate("1234567890"):
    if digit in "1":
        finger = "LP"
    elif digit in "2":
        finger = "LR"
    elif digit in "3":
        finger = "LM"
    elif digit in "45":
        finger = "LI"
    elif digit in "67":
        finger = "RI"
    elif digit in "8":
        finger = "RM"
    elif digit in "9":
        finger = "RR"
    else:
        finger = "RP"

    KEYBOARD[digit] = Key(
        letter=digit,
        x=float(column),
        y=-1.0,
        finger=finger,
        hand="L" if finger.startswith("L") else "R",
        home_x=FINGER_HOME[finger][0],
        home_y=FINGER_HOME[finger][1],
    )


def distance(x1: float, y1: float, x2: float, y2: float) -> float:
    return math.hypot(x2 - x1, y2 - y1)


def home_distance(key: Key) -> float:
    return distance(key.home_x, key.home_y, key.x, key.y)


def key_effort(key: Key) -> float:
    dist = home_distance(key)
    row_jump = abs(key.y - key.home_y)
    effort = 0.35 + FINGER_WEIGHT[key.finger] * (dist**1.35)

    if row_jump == 1:
        effort += 0.12
    if key.finger in {"LI", "RI"} and key.letter in {"b", "y"}:
        effort += 0.35
    if key.finger in {"LP", "RP"} and key.y == 0:
        effort += 0.25

    return effort


def transition_effort(left: Key, right: Key) -> float:
    jump = distance(left.x, left.y, right.x, right.y)
    row_jump = abs(left.y - right.y)

    if left.finger == right.finger:
        if left.letter == right.letter:
            return 0.9

        effort = 1.25 + 0.75 * jump
        if left.finger in {"LP", "RP"}:
            effort += 0.5
            if row_jump >= 1:
                effort += 0.15
        if row_jump >= 2:
            effort += 0.9
        elif row_jump == 1:
            effort += 0.25
        return effort

    if left.hand == right.hand:
        effort = 0.28 + 0.15 * jump
        finger_span = abs(
            FINGER_ORDER[left.hand][left.finger]
            - FINGER_ORDER[right.hand][right.finger]
        )
        touches_bottom_row = left.y == 2.0 or right.y == 2.0
        if finger_span >= 2 and touches_bottom_row:
            effort += 0.30 * (finger_span - 1) + 0.08 * jump
        if left.y == right.y == 2.0:
            effort += 0.35 + 0.12 * jump
        if row_jump >= 2:
            effort += 0.35
        return effort

    effort = 0.04 * jump
    effort += 0.08 * (home_distance(left) + home_distance(right))
    if row_jump >= 2:
        effort += 0.18
    elif row_jump == 1:
        effort += 0.04
    return effort


def trigram_effort(first: Key, second: Key, third: Key) -> float:
    if any(key.letter == "-" or key.letter.isdigit() for key in (first, second, third)):
        return 0.0

    row_turn = (first.y - second.y) * (second.y - third.y) < 0
    if first.hand != third.hand or first.hand == second.hand or not row_turn:
        return 0.0

    row_span = max(first.y, second.y, third.y) - min(first.y, second.y, third.y)
    effort = 0.24 * distance(first.x, first.y, third.x, third.y)
    effort += 0.16 * (
        home_distance(first) + home_distance(second) + home_distance(third)
    )
    effort += 0.7 * row_span
    return effort


def score_word(word: str) -> dict[str, float | int | str]:
    normalized = word.lower()
    unsupported = [letter for letter in normalized if letter not in KEYBOARD]
    if unsupported:
        raise ValueError(
            "Only lowercase letters a-z, digits 0-9, and '-' are supported: "
            + ", ".join(sorted(set(unsupported)))
        )

    keys = [KEYBOARD[letter] for letter in normalized]
    base_total = sum(key_effort(key) for key in keys)
    transition_total = 0.0
    trigram_total = 0.0
    same_finger = 0
    same_hand = 0
    hand_alternations = 0

    for left, right in zip(keys, keys[1:], strict=False):
        transition_total += transition_effort(left, right)
        if left.finger == right.finger:
            same_finger += 1
        elif left.hand == right.hand:
            same_hand += 1
        else:
            hand_alternations += 1

    for first, second, third in zip(keys, keys[1:], keys[2:], strict=False):
        trigram_total += trigram_effort(first, second, third)

    trigram_total *= min(1.0, 6 / len(keys))
    total = base_total + transition_total + trigram_total
    per_char = total / len(keys)

    return {
        "word": word,
        "letters": len(keys),
        "base_total": base_total,
        "transition_total": transition_total,
        "trigram_total": trigram_total,
        "total": total,
        "per_char": per_char,
        "same_finger": same_finger,
        "same_hand": same_hand,
        "hand_alternations": hand_alternations,
    }


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description=(
            "Score how awkward a word is to touch-type on standard QWERTY."
        )
    )
    parser.add_argument("words", nargs="*", help="word(s) to score")
    parser.add_argument(
        "--file",
        action="append",
        default=[],
        help="read one word per line from a file",
    )
    parser.add_argument(
        "--sort",
        choices=("input", "score"),
        default="score",
        help="output order",
    )
    return parser


def read_words(paths: list[str]) -> list[str]:
    words: list[str] = []
    for path in paths:
        with open(path, encoding="utf-8") as handle:
            for raw_line in handle:
                word = raw_line.strip()
                if not word or word.startswith("#"):
                    continue
                words.append(word)
    return words


def main() -> int:
    parser = build_parser()
    args = parser.parse_args()
    words = [*args.words, *read_words(args.file)]
    if not words:
        parser.error("provide at least one word or use --file")

    try:
        results = [score_word(word) for word in words]
    except ValueError as exc:
        parser.exit(2, f"worddistance: {exc}\n")

    if args.sort == "score":
        results.sort(key=lambda item: item["total"], reverse=True)

    print(
        "word".ljust(12),
        "score".rjust(8),
        "char".rjust(8),
        "base".rjust(8),
        "jump".rjust(8),
        "path".rjust(8),
        "sfb".rjust(5),
        "same".rjust(5),
        "alt".rjust(5),
    )
    for result in results:
        print(
            str(result["word"]).ljust(12),
            f"{result['total']:.2f}".rjust(8),
            f"{result['per_char']:.2f}".rjust(8),
            f"{result['base_total']:.2f}".rjust(8),
            f"{result['transition_total']:.2f}".rjust(8),
            f"{result['trigram_total']:.2f}".rjust(8),
            str(result["same_finger"]).rjust(5),
            str(result["same_hand"]).rjust(5),
            str(result["hand_alternations"]).rjust(5),
        )

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
