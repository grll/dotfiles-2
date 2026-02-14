# ── Shared aliases & config (sourced by local and remote bashrc) ──
[[ -f "$HOME/dotfiles/config.sh" ]] && source "$HOME/dotfiles/config.sh"

# Disable Claude Code auto title (we set it via hooks)
export CLAUDE_CODE_DISABLE_TERMINAL_TITLE=1

# ── Command shortcuts ─────────────────────────────────
alias cld='claude'
alias deepwiki-on='claude mcp add -t http deepwiki https://mcp.deepwiki.com/mcp'
alias deepwiki-off='claude mcp remove deepwiki'
alias uvsa='uv sync --all-packages --all-groups --all-extras'
