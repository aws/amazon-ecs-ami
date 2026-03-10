#!/usr/bin/env bash
set -euo pipefail

# Generates a CHANGELOG.md entry for the current release by:
# 1. Comparing old vs new release var files to detect what changed
# 2. Querying merged PRs since the last release for changelog entries
# 3. Prepending the new entry to CHANGELOG.md
#
# Usage: ./scripts/generate-changelog.sh
# Must be run after check-update.sh has updated the release var files.
# Expects old release values saved in release-al2.old.values and release-al2023.old.values

readonly REPO="aws/amazon-ecs-ami"
readonly CHANGELOG="CHANGELOG.md"
readonly DATE=$(date '+%Y%m%d')

# Parse a value from a .hcl file: parse_hcl_value <file> <key>
parse_hcl_value() {
    local file="$1" key="$2"
    grep "^${key} " "$file" 2>/dev/null | sed 's/.*= *"\(.*\)"/\1/' || echo ""
}

# Read current (new) values
read_new_values() {
    new_ami_version_al2=$(parse_hcl_value "release-al2.auto.pkrvars.hcl" "ami_version_al2")
    new_ecs_version_al2=$(parse_hcl_value "release-al2.auto.pkrvars.hcl" "ecs_agent_version")
    new_source_ami_al2=$(parse_hcl_value "release-al2.auto.pkrvars.hcl" "source_ami_al2")
    new_source_ami_al2arm=$(parse_hcl_value "release-al2.auto.pkrvars.hcl" "source_ami_al2arm")
    new_source_ami_al2kernel5dot10=$(parse_hcl_value "release-al2.auto.pkrvars.hcl" "source_ami_al2kernel5dot10")
    new_source_ami_al2kernel5dot10arm=$(parse_hcl_value "release-al2.auto.pkrvars.hcl" "source_ami_al2kernel5dot10arm")

    new_ami_version_al2023=$(parse_hcl_value "release-al2023.auto.pkrvars.hcl" "ami_version_al2023")
    new_ecs_version_al2023=$(parse_hcl_value "release-al2023.auto.pkrvars.hcl" "ecs_agent_version")
    new_source_ami_al2023=$(parse_hcl_value "release-al2023.auto.pkrvars.hcl" "source_ami_al2023")
    new_source_ami_al2023arm=$(parse_hcl_value "release-al2023.auto.pkrvars.hcl" "source_ami_al2023arm")
}

# Read old (saved) values
read_old_values() {
    if [ -f "release-al2.old.values" ]; then
        old_ami_version_al2=$(parse_hcl_value "release-al2.old.values" "ami_version_al2")
        old_ecs_version_al2=$(parse_hcl_value "release-al2.old.values" "ecs_agent_version")
        old_source_ami_al2=$(parse_hcl_value "release-al2.old.values" "source_ami_al2")
        old_source_ami_al2arm=$(parse_hcl_value "release-al2.old.values" "source_ami_al2arm")
        old_source_ami_al2kernel5dot10=$(parse_hcl_value "release-al2.old.values" "source_ami_al2kernel5dot10")
        old_source_ami_al2kernel5dot10arm=$(parse_hcl_value "release-al2.old.values" "source_ami_al2kernel5dot10arm")
    else
        old_ami_version_al2="" old_ecs_version_al2="" old_source_ami_al2=""
        old_source_ami_al2arm="" old_source_ami_al2kernel5dot10="" old_source_ami_al2kernel5dot10arm=""
    fi

    if [ -f "release-al2023.old.values" ]; then
        old_ami_version_al2023=$(parse_hcl_value "release-al2023.old.values" "ami_version_al2023")
        old_ecs_version_al2023=$(parse_hcl_value "release-al2023.old.values" "ecs_agent_version")
        old_source_ami_al2023=$(parse_hcl_value "release-al2023.old.values" "source_ami_al2023")
        old_source_ami_al2023arm=$(parse_hcl_value "release-al2023.old.values" "source_ami_al2023arm")
    else
        old_ami_version_al2023="" old_ecs_version_al2023="" old_source_ami_al2023="" old_source_ami_al2023arm=""
    fi
}

# Detect which AMI types were updated
detect_updates() {
    al2_updated="false"
    al2023_updated="false"

    if [ -n "$new_ami_version_al2" ] && [ "$new_ami_version_al2" != "$old_ami_version_al2" ]; then
        al2_updated="true"
    fi
    if [ -n "$new_ami_version_al2023" ] && [ "$new_ami_version_al2023" != "$old_ami_version_al2023" ]; then
        al2023_updated="true"
    fi
}

# Append a line to the entry file
add_line() {
    echo "$1" >> "$ENTRY_FILE"
}

# Build the changelog entry into a temp file
build_changelog_entry() {
    ENTRY_FILE=$(mktemp)

    # Header
    echo "## ${DATE}" > "$ENTRY_FILE"

    # AMI version line (clubbed if both updated)
    if [ "$al2_updated" = "true" ] && [ "$al2023_updated" = "true" ]; then
        add_line "- al2, al2023 ami version: ${DATE}"
    elif [ "$al2_updated" = "true" ]; then
        add_line "- al2 ami version: ${DATE}"
    elif [ "$al2023_updated" = "true" ]; then
        add_line "- al2023 ami version: ${DATE}"
    fi

    # ECS version (only if changed)
    local new_ecs="${new_ecs_version_al2:-$new_ecs_version_al2023}"
    local old_ecs="${old_ecs_version_al2:-$old_ecs_version_al2023}"
    if [ -n "$new_ecs" ] && [ "$new_ecs" != "$old_ecs" ]; then
        add_line "- ecs version: ${new_ecs}"
    fi

    # AL2 source AMIs (only changed ones)
    if [ "$al2_updated" = "true" ]; then
        [ "$new_source_ami_al2" != "$old_source_ami_al2" ] && [ -n "$new_source_ami_al2" ] && \
            add_line "- source al2 ami: ${new_source_ami_al2}"
        [ "$new_source_ami_al2arm" != "$old_source_ami_al2arm" ] && [ -n "$new_source_ami_al2arm" ] && \
            add_line "- source al2 arm ami: ${new_source_ami_al2arm}"
        [ "$new_source_ami_al2kernel5dot10" != "$old_source_ami_al2kernel5dot10" ] && [ -n "$new_source_ami_al2kernel5dot10" ] && \
            add_line "- source al2 kernel 5.10 ami: ${new_source_ami_al2kernel5dot10}"
        [ "$new_source_ami_al2kernel5dot10arm" != "$old_source_ami_al2kernel5dot10arm" ] && [ -n "$new_source_ami_al2kernel5dot10arm" ] && \
            add_line "- source al2 kernel 5.10 arm ami: ${new_source_ami_al2kernel5dot10arm}"
    fi

    # AL2023 source AMIs (only changed ones)
    if [ "$al2023_updated" = "true" ]; then
        [ "$new_source_ami_al2023" != "$old_source_ami_al2023" ] && [ -n "$new_source_ami_al2023" ] && \
            add_line "- source al2023 ami: ${new_source_ami_al2023}"
        [ "$new_source_ami_al2023arm" != "$old_source_ami_al2023arm" ] && [ -n "$new_source_ami_al2023arm" ] && \
            add_line "- source al2023 arm ami: ${new_source_ami_al2023arm}"
    fi

    # PR changelog entries
    fetch_pr_changelogs

    echo "$ENTRY_FILE"
}

# Fetch merged PR changelog entries since last release
# Excludes housekeeping entries, sorts: feature > enhancement > bugfix > uncategorized
fetch_pr_changelogs() {
    local last_release_date
    last_release_date=$(grep -m1 '^## [0-9]' "$CHANGELOG" | sed 's/## //')

    if [ -z "$last_release_date" ]; then
        echo "WARNING: Could not find last release date in CHANGELOG.md" >&2
        return
    fi

    # Convert YYYYMMDD to YYYY-MM-DD for GitHub search
    local search_date="${last_release_date:0:4}-${last_release_date:4:2}-${last_release_date:6:2}"
    echo "Fetching merged PRs since ${search_date}..." >&2

    # Get merged PR numbers since last release, exclude release PRs
    local pr_numbers
    pr_numbers=$(gh pr list \
        --repo "$REPO" \
        --state merged \
        --base main \
        --search "merged:>${search_date}" \
        --json number,headRefName \
        --jq '.[] | select(.headRefName | startswith("release-") | not) | .number' 2>/dev/null || true)

    if [ -z "$pr_numbers" ]; then
        return
    fi

    # Collect entries by category for sorting
    local features="" enhancements="" bugfixes=""

    for pr_num in $pr_numbers; do
        local pr_body
        pr_body=$(gh pr view "$pr_num" --repo "$REPO" --json body --jq '.body' 2>/dev/null || true)

        if [ -z "$pr_body" ]; then
            continue
        fi

        # Write PR body to temp file for reliable sed processing
        local tmpfile
        tmpfile=$(mktemp)
        echo "$pr_body" > "$tmpfile"

        # Extract changelog section, strip HTML comments, get first non-empty line
        local changelog_entry
        changelog_entry=$(sed 's/<!--.*-->//g' "$tmpfile" \
            | tr -d '\r' \
            | sed '/<!--/,/-->/d' \
            | sed -n '/### Description for the changelog/,/### Licensing/p' \
            | grep -v '^###' \
            | grep -v '^[[:space:]]*$' \
            | head -1 \
            | sed 's/^[[:space:]]*-[[:space:]]*//' \
            | sed 's/^[[:space:]]*//' \
            || true)

        rm -f "$tmpfile"

        if [ -z "$changelog_entry" ]; then
            continue
        fi

        # Skip housekeeping entries
        if echo "$changelog_entry" | grep -qi '^housekeeping'; then
            echo "Skipping housekeeping entry: ${changelog_entry}" >&2
            continue
        fi

        local line="- ${changelog_entry} [#${pr_num}](https://github.com/${REPO}/pull/${pr_num})"

        # Sort into category buckets
        if echo "$changelog_entry" | grep -qi '^feature'; then
            features+="${line}"$'\n'
        elif echo "$changelog_entry" | grep -qi '^enhancement'; then
            enhancements+="${line}"$'\n'
        elif echo "$changelog_entry" | grep -qi '^bug\s*fix\|^bugfix\|^fix'; then
            bugfixes+="${line}"$'\n'
        fi
    done

    # Output in priority order: feature > enhancement > bugfix > other
    [ -n "$features" ] && printf '%s' "$features" >> "$ENTRY_FILE"
    [ -n "$enhancements" ] && printf '%s' "$enhancements" >> "$ENTRY_FILE"
    [ -n "$bugfixes" ] && printf '%s' "$bugfixes" >> "$ENTRY_FILE"
}

# Prepend entry to CHANGELOG.md (after the header section)
prepend_to_changelog() {
    local entry_file="$1"

    # Find the line number of the first release entry (## YYYYMMDD)
    local first_release_line
    first_release_line=$(grep -n '^## [0-9]' "$CHANGELOG" | head -1 | cut -d: -f1)

    if [ -z "$first_release_line" ]; then
        echo "ERROR: Could not find any release entry in CHANGELOG.md" >&2
        exit 1
    fi

    # Build new changelog: header + new entry + blank line + existing entries
    local tmpfile
    tmpfile=$(mktemp)
    head -n $((first_release_line - 1)) "$CHANGELOG" > "$tmpfile"
    cat "$entry_file" >> "$tmpfile"
    echo "" >> "$tmpfile"
    tail -n +${first_release_line} "$CHANGELOG" >> "$tmpfile"
    mv "$tmpfile" "$CHANGELOG"
}

# Main
main() {
    read_new_values
    read_old_values
    detect_updates

    if [ "$al2_updated" = "false" ] && [ "$al2023_updated" = "false" ]; then
        echo "No AMI updates detected, skipping changelog generation"
        exit 0
    fi

    echo "Generating changelog entry for ${DATE}..."
    local entry_file
    entry_file=$(build_changelog_entry)

    echo "--- Changelog entry ---"
    cat "$entry_file"
    echo "--- End ---"

    prepend_to_changelog "$entry_file"
    rm -f "$entry_file"
    git add "$CHANGELOG"

    echo "CHANGELOG.md updated and staged"
}

main
