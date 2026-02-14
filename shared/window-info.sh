# Get focused window info from kitty
# Output: is_remote|local_cwd|remote_cwd (pipe-separated)
# Uses foreground_processes[0].cwd for accurate local cwd
get_focused_window() {
    kitten @ ls | jq -r '
      .[] | select(.is_focused) | .tabs[] | select(.is_focused) |
      (.windows[] | select(.is_self == false)) // .windows[0] |
      (.foreground_processes[0].cwd // .cwd) as $local_cwd |
      "\(.user_vars.is_remote // "")|\($local_cwd)|\(.user_vars.remote_cwd // "")"
    '
}
