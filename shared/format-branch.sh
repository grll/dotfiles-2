# Format branch name for display: strip user/ prefix, extract ticket ID, uppercase
# Usage: format_branch "user/sol-3295-description" → "SOL-3295"
format_branch() {
    local branch="$1"
    # Strip user/ prefix if present
    branch="${branch#*/}"
    # Check for Linear ticket pattern (e.g., sol-3295-description)
    if [[ "$branch" =~ ^([a-zA-Z]+-[0-9]+) ]]; then
        echo "${BASH_REMATCH[1]^^}"  # Uppercase ticket ID
    else
        echo "$branch"
    fi
}
