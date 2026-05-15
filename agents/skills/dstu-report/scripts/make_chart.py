#!/usr/bin/env python3
import argparse
import csv
from pathlib import Path

import matplotlib.pyplot as plt


def read_rows(path: Path):
    with path.open("r", encoding="utf-8", newline="") as f:
        reader = csv.DictReader(f)
        rows = list(reader)
    if not rows:
        raise ValueError("CSV file is empty")
    if "label" not in reader.fieldnames or "value" not in reader.fieldnames:
        raise ValueError("CSV file must contain 'label' and 'value' columns")
    labels = [row["label"] for row in rows]
    values = [float(row["value"]) for row in rows]
    return labels, values


def main():
    parser = argparse.ArgumentParser(
        description="Generate a simple bar chart for Typst reports from a CSV file."
    )
    parser.add_argument("input", help="CSV file with columns: label,value")
    parser.add_argument("output", help="Output image path, e.g. chart.png")
    parser.add_argument("--title", default="", help="Chart title")
    parser.add_argument("--xlabel", default="", help="X axis label")
    parser.add_argument("--ylabel", default="", help="Y axis label")
    args = parser.parse_args()

    labels, values = read_rows(Path(args.input))

    plt.figure(figsize=(8, 4.5), dpi=200)
    bars = plt.bar(labels, values, color="#4C6A92")
    if args.title:
        plt.title(args.title)
    if args.xlabel:
        plt.xlabel(args.xlabel)
    if args.ylabel:
        plt.ylabel(args.ylabel)
    plt.grid(axis="y", linestyle="--", linewidth=0.6, alpha=0.5)
    plt.gca().set_axisbelow(True)
    plt.tight_layout()

    for bar, value in zip(bars, values):
        plt.text(
            bar.get_x() + bar.get_width() / 2,
            bar.get_height(),
            f"{value:g}",
            ha="center",
            va="bottom",
            fontsize=9,
        )

    output = Path(args.output)
    output.parent.mkdir(parents=True, exist_ok=True)
    plt.savefig(output, bbox_inches="tight")


if __name__ == "__main__":
    main()
