#!/usr/bin/env python3
"""Checks agent skills against the Agent Skills format.

Each skills/<name>/SKILL.md needs YAML front matter with a `name` that matches
its directory (lowercase letters, digits and single hyphens, at most 64
characters) and a `description` of at most 1024 characters, followed by a body.
"""

import pathlib
import re
import sys

NAME = re.compile(r"^[a-z0-9]+(-[a-z0-9]+)*$")


def front_matter(text: str) -> tuple[dict[str, str], str]:
    match = re.match(r"^---\n(.*?)\n---\n(.*)$", text, re.S)
    if not match:
        raise ValueError("missing front matter delimited by --- lines")
    fields = {}
    for line in match.group(1).splitlines():
        key, sep, value = line.partition(":")
        if sep and not line.startswith((" ", "\t")):
            fields[key.strip()] = value.strip()
    return fields, match.group(2)


def check(skill: pathlib.Path) -> list[str]:
    errors = []
    try:
        fields, body = front_matter(skill.read_text(encoding="utf-8"))
    except ValueError as error:
        return [str(error)]
    name = fields.get("name", "")
    if not NAME.match(name) or len(name) > 64:
        errors.append(f"invalid name {name!r}")
    if name != skill.parent.name:
        errors.append(f"name {name!r} differs from directory {skill.parent.name!r}")
    description = fields.get("description", "")
    if not description:
        errors.append("missing description")
    elif len(description) > 1024:
        errors.append(f"description has {len(description)} characters; max 1024")
    if not body.strip():
        errors.append("empty body")
    return errors


def main() -> int:
    root = pathlib.Path(sys.argv[1] if len(sys.argv) > 1 else "skills")
    skills = sorted(root.glob("*/SKILL.md"))
    if not skills:
        print(f"No skills found under {root}.")
        return 1
    failed = False
    for skill in skills:
        for error in check(skill):
            print(f"{skill}: {error}")
            failed = True
    if not failed:
        print(f"Checked {len(skills)} skill(s).")
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main())
