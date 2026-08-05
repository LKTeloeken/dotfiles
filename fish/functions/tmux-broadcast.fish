function tmux-broadcast --description "Send a command to all tmux windows"
    if test (count $argv) -eq 0
        echo "Usage: tmux-broadcast [-a] <command>"
        echo "  -a  target all sessions (default: current session only)"
        return 1
    end

    set -l all_sessions false
    if test "$argv[1]" = "-a"
        set all_sessions true
        set argv $argv[2..]
    end

    set -l cmd (string join " " $argv)

    if $all_sessions
        set -l targets (tmux list-windows -a -F '#{session_name}:#{window_index}')
    else
        set -l targets (tmux list-windows -F '#I')
    end

    for target in $targets
        tmux send-keys -t $target $cmd Enter
    end
end
