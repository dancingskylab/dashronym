#!/usr/bin/env python3
"""Fail CI when an LCOV report falls below line or branch thresholds."""

from __future__ import annotations

import argparse
from pathlib import Path


def _percentage(covered: int, found: int) -> float:
    return covered * 100 / found if found else 0.0


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("report", type=Path)
    parser.add_argument("--min-lines", type=float, required=True)
    parser.add_argument("--min-branches", type=float, required=True)
    args = parser.parse_args()

    lines_found = 0
    lines_covered = 0
    branches_found = 0
    branches_covered = 0

    for raw_line in args.report.read_text(encoding="utf-8").splitlines():
        if raw_line.startswith("DA:"):
            lines_found += 1
            # LCOV permits an optional checksum after the execution count.
            hit_count = int(raw_line.split(",")[1])
            lines_covered += hit_count > 0
        elif raw_line.startswith("BRDA:"):
            branches_found += 1
            taken = raw_line.rsplit(",", maxsplit=1)[1]
            branches_covered += taken not in {"-", "0"}

    line_rate = _percentage(lines_covered, lines_found)
    branch_rate = _percentage(branches_covered, branches_found)
    print(
        f"Lines: {lines_covered}/{lines_found} ({line_rate:.2f}%), "
        f"branches: {branches_covered}/{branches_found} "
        f"({branch_rate:.2f}%)."
    )

    failures: list[str] = []
    if lines_found == 0:
        failures.append("the report contains no line records")
    elif line_rate < args.min_lines:
        failures.append(
            f"line coverage {line_rate:.2f}% is below "
            f"{args.min_lines:.2f}%"
        )

    if branches_found == 0:
        failures.append("the report contains no branch records")
    elif branch_rate < args.min_branches:
        failures.append(
            f"branch coverage {branch_rate:.2f}% is below "
            f"{args.min_branches:.2f}%"
        )

    if failures:
        print("Coverage check failed: " + "; ".join(failures) + ".")
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
