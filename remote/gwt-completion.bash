_gwt() {
    local cur prev
    COMPREPLY=()
    cur="${COMP_WORDS[COMP_CWORD]}"
    prev="${COMP_WORDS[COMP_CWORD-1]}"

    local repo_name
    repo_name="$(basename "$REMOTE_REPO")"

    local branches
    branches="$(
        git -C "$REMOTE_REPO" worktree list --porcelain 2>/dev/null \
            | grep '^worktree ' | sed 's|^worktree ||' \
            | grep -v "^${REMOTE_REPO}$" \
            | while read -r p; do
                basename "$p" | sed "s|^${repo_name}-||"
            done
    )"

    case "$prev" in
        -b) return ;;
        -d) COMPREPLY=( $(compgen -W "$branches" -- "$cur") ); return ;;
    esac

    if [[ "$cur" == -* ]]; then
        COMPREPLY=( $(compgen -W "-b -d -l -h" -- "$cur") )
    else
        COMPREPLY=( $(compgen -W "$branches" -- "$cur") )
    fi
}

complete -F _gwt gwt
