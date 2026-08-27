#!/bin/bash
set -euo pipefail

SKILLS_DIR="$(cd "$(dirname "$0")" && pwd)"
scan_roots=("$SKILLS_DIR")
failed=0

report_matches() {
    local label=$1
    local pattern=$2
    local case_sensitivity=${3:-insensitive}
    local matches

    if [ "$case_sensitivity" = "sensitive" ]; then
        matches=$(rg -l -- "$pattern" "${scan_roots[@]}" || true)
    else
        matches=$(rg -li -- "$pattern" "${scan_roots[@]}" || true)
    fi
    if [ -n "$matches" ]; then
        echo "$label"
        echo "$matches"
        failed=1
    fi
}

report_credential_assignments() {
    local pattern='(api[_-]?key|access[_-]?token|auth[_-]?token|client[_-]?secret|password)[[:space:]]*[:=][[:space:]]*[A-Za-z0-9_./+:-]{16,}'
    local safe_clerk_docs='^\./shared/clerk-expo/references/custom-flows\.md:[0-9]+:> - (Email/password|Forgot password): https://clerk\.com/docs/guides/development/custom-flows/authentication/(email-password|forgot-password)$'
    local matches

    matches=$(cd "$SKILLS_DIR" && rg -ni -- "$pattern" . | rg -v -- "$safe_clerk_docs" || true)
    if [ -n "$matches" ]; then
        echo "Credential assignments"
        echo "$matches"
        failed=1
    fi
}

check_local_references() {
    local matches

    matches=$(python3 - "$SKILLS_DIR/shared" <<'PY'
import re
import sys
from pathlib import Path
from urllib.parse import unquote, urlsplit

shared_root = Path(sys.argv[1]).resolve()
reference_definition_pattern = re.compile(
    r'^\s{0,3}\[([^\]]+)\]:\s*(?:<([^>]+)>|(\S+))'
)
reference_usage_pattern = re.compile(r"!?\[([^\]]+)\]\[([^\]]*)\]")
fence_pattern = re.compile(
    r"^(?:\s{0,3}>\s?)*\s{0,3}((?:\x60){3,}|~{3,})"
)
inline_code_pattern = re.compile(r"((?:\x60)+).*?\1")


def normalize_label(label):
    return " ".join(label.split()).casefold()


def mask_inline_code(line):
    return inline_code_pattern.sub(lambda match: " " * len(match.group(0)), line)


def is_escaped(text, index):
    backslashes = 0
    index -= 1
    while index >= 0 and text[index] == "\\":
        backslashes += 1
        index -= 1
    return backslashes % 2 == 1


def find_closing_bracket(line, opener):
    depth = 1
    index = opener + 1
    while index < len(line):
        if line[index] == "\\" and index + 1 < len(line):
            index += 2
            continue
        if line[index] == "[":
            depth += 1
        elif line[index] == "]":
            depth -= 1
            if depth == 0:
                return index
        index += 1
    return None


def consume_link_tail(line, index):
    while index < len(line) and line[index].isspace():
        index += 1
    if index >= len(line):
        return None
    if line[index] == ")":
        return index + 1

    title_opener = line[index]
    if title_opener not in {'"', "'", "("}:
        return None
    title_closer = ")" if title_opener == "(" else title_opener
    index += 1
    title_depth = 1
    while index < len(line):
        if line[index] == "\\" and index + 1 < len(line):
            index += 2
            continue
        if title_opener == "(" and line[index] == "(":
            title_depth += 1
        elif line[index] == title_closer:
            title_depth -= 1
            if title_depth == 0:
                index += 1
                break
        index += 1
    else:
        return None

    while index < len(line) and line[index].isspace():
        index += 1
    if index < len(line) and line[index] == ")":
        return index + 1
    return None


def parse_inline_destination(line, index):
    while index < len(line) and line[index].isspace():
        index += 1
    if index >= len(line):
        return None

    destination = []
    if line[index] == "<":
        index += 1
        while index < len(line):
            if line[index] == "\\" and index + 1 < len(line):
                destination.append(line[index + 1])
                index += 2
                continue
            if line[index] == ">":
                link_end = consume_link_tail(line, index + 1)
                if link_end is None:
                    return None
                return "".join(destination), link_end
            destination.append(line[index])
            index += 1
        return None

    depth = 0
    while index < len(line):
        character = line[index]
        if character == "\\" and index + 1 < len(line):
            destination.append(line[index + 1])
            index += 2
            continue
        if character == "(":
            depth += 1
            destination.append(character)
        elif character == ")":
            if depth == 0:
                return "".join(destination), index + 1
            depth -= 1
            destination.append(character)
        elif character.isspace() and depth == 0:
            link_end = consume_link_tail(line, index)
            if link_end is None:
                return None
            return "".join(destination), link_end
        else:
            destination.append(character)
        index += 1
    return None


def inline_destinations(line):
    cursor = 0
    while cursor < len(line):
        opener = line.find("[", cursor)
        if opener == -1:
            return
        if is_escaped(line, opener):
            cursor = opener + 1
            continue

        closer = find_closing_bracket(line, opener)
        if closer is None:
            return
        if closer + 1 >= len(line) or line[closer + 1] != "(":
            cursor = opener + 1
            continue

        parsed = parse_inline_destination(line, closer + 2)
        if parsed is None:
            cursor = closer + 1
            continue
        destination, cursor = parsed
        yield destination


def check_destination(markdown_file, line_number, destination):
    destination = destination.strip()
    if destination.startswith("<") and ">" in destination:
        destination = destination[1:destination.index(">")]

    if destination.startswith("#"):
        return

    if destination.startswith("~/") or re.match(r"^[A-Za-z]:[\\/]", destination):
        print(
            f"{markdown_file}:{line_number}: "
            f"local reference escapes shared skill root: {destination}"
        )
        return

    try:
        parsed = urlsplit(destination)
    except ValueError:
        print(f"{markdown_file}:{line_number}: invalid link destination: {destination}")
        return

    if parsed.scheme:
        if parsed.scheme.casefold() == "file":
            print(
                f"{markdown_file}:{line_number}: "
                f"local reference escapes shared skill root: {destination}"
            )
        return
    if parsed.netloc:
        return

    relative_path = unquote(parsed.path)
    if not relative_path:
        return
    if relative_path.startswith("/"):
        print(
            f"{markdown_file}:{line_number}: "
            f"local reference escapes shared skill root: {destination}"
        )
        return

    resolved = (markdown_file.parent / relative_path).resolve()
    try:
        resolved.relative_to(shared_root)
    except ValueError:
        print(
            f"{markdown_file}:{line_number}: "
            f"local reference escapes shared skill root: {destination}"
        )
        return

    if not resolved.exists():
        print(f"{markdown_file}:{line_number}: missing local reference: {destination}")

for markdown_file in sorted(shared_root.rglob("*.md")):
    definitions = {}
    usages = []
    fence_character = None
    fence_length = 0

    for line_number, line in enumerate(markdown_file.read_text().splitlines(), start=1):
        fence_match = fence_pattern.match(line)
        if fence_match:
            marker = fence_match.group(1)
            if fence_character is None:
                fence_character = marker[0]
                fence_length = len(marker)
            elif marker[0] == fence_character and len(marker) >= fence_length:
                fence_character = None
                fence_length = 0
            continue
        if fence_character is not None:
            continue

        scan_line = mask_inline_code(line)
        definition_match = reference_definition_pattern.match(scan_line)
        if definition_match:
            label = normalize_label(definition_match.group(1))
            destination = definition_match.group(2) or definition_match.group(3)
            definitions[label] = line_number
            check_destination(markdown_file, line_number, destination)
            continue

        for destination in inline_destinations(scan_line):
            check_destination(markdown_file, line_number, destination)

        for match in reference_usage_pattern.finditer(scan_line):
            label = normalize_label(match.group(2) or match.group(1))
            usages.append((label, line_number))

    for label, line_number in usages:
        if label not in definitions:
            print(
                f"{markdown_file}:{line_number}: "
                f"missing Markdown reference definition: {label}"
            )
PY
)

    if [ -n "$matches" ]; then
        echo "$matches"
        failed=1
    fi
}

echo "Checking skill frontmatter"
while IFS= read -r skill_file; do
    frontmatter=$(awk 'NR == 1 && $0 == "---" { next } $0 == "---" { exit } { print }' "$skill_file")
    if ! echo "$frontmatter" | rg -q '^name:'; then
        echo "Missing name: $skill_file"
        failed=1
    fi
    if ! echo "$frontmatter" | rg -q '^description:'; then
        echo "Missing description: $skill_file"
        failed=1
    fi
done < <(fd -HI -tf '^SKILL\.md$' "${scan_roots[@]}")

echo "Checking local skill references"
check_local_references

echo "Checking risky file names"
risky_files=$(fd -HI -tf '(\.env($|\.)|\.pem$|\.key$|\.p12$|\.pfx$|credentials|secrets?)' "${scan_roots[@]}" || true)
if [ -n "$risky_files" ]; then
    echo "$risky_files"
    failed=1
fi

report_matches "Private key material" 'BEGIN (RSA |OPENSSH |EC |DSA )?PRIVATE KEY'
report_matches "Token-shaped values" '(ghp_[A-Za-z0-9]{20,}|github_pat_[A-Za-z0-9_]{20,}|xox[baprs]-[A-Za-z0-9-]{10,}|AKIA[0-9A-Z]{16}|AIza[0-9A-Za-z_-]{30,}|sk-[A-Za-z0-9_-]{20,}|https://[A-Za-z0-9]{20,}@[^[:space:]/]+)'
report_credential_assignments
report_matches "Hard-coded macOS home paths" '/Users/[A-Za-z0-9._-]+/' sensitive

if [ "$failed" -ne 0 ]; then
    echo "Skill audit failed" >&2
    exit 1
fi

echo "Skill audit passed"
