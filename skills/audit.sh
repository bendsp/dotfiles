#!/bin/bash
set -euo pipefail

SKILLS_DIR="$(cd "$(dirname "$0")" && pwd)"
scan_roots=("$SKILLS_DIR")
failed=0

report_matches() {
    local label=$1
    local pattern=$2
    local matches

    matches=$(rg -li -- "$pattern" "${scan_roots[@]}" || true)
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

echo "Checking risky file names"
risky_files=$(fd -HI -tf '(\.env($|\.)|\.pem$|\.key$|\.p12$|\.pfx$|credentials|secrets?)' "${scan_roots[@]}" || true)
if [ -n "$risky_files" ]; then
    echo "$risky_files"
    failed=1
fi

report_matches "Private key material" 'BEGIN (RSA |OPENSSH |EC |DSA )?PRIVATE KEY'
report_matches "Token-shaped values" '(ghp_[A-Za-z0-9]{20,}|github_pat_[A-Za-z0-9_]{20,}|xox[baprs]-[A-Za-z0-9-]{10,}|AKIA[0-9A-Z]{16}|AIza[0-9A-Za-z_-]{30,}|sk-[A-Za-z0-9_-]{20,}|https://[A-Za-z0-9]{20,}@[^[:space:]/]+)'
report_credential_assignments
report_matches "Hard-coded macOS home paths" '/Users/[A-Za-z0-9._-]+/'

if [ "$failed" -ne 0 ]; then
    echo "Skill audit failed" >&2
    exit 1
fi

echo "Skill audit passed"
