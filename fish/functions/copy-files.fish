function copy-files
    set target_dir $argv[1]
    
    # Update this path to where you saved the Lua script
    set script_path "$HOME/Documents/projects/personal/scripts/gather_code.lua"

    if test -z "$target_dir"
        echo "Please provide a directory path."
        return 1
    end

    # Check for clipboard utility and run the script
    if type -q pbcopy
        # macOS
        lua $script_path $target_dir | pbcopy
        echo "Files from '$target_dir' copied to clipboard (macOS)!"
    else if type -q wl-copy
        # Linux Wayland
        lua $script_path $target_dir | wl-copy
        echo "Files from '$target_dir' copied to clipboard (Wayland)!"
    else if type -q xclip
        # Linux X11
        lua $script_path $target_dir | xclip -selection clipboard
        echo "Files from '$target_dir' copied to clipboard (X11)!"
    else if type -q clip.exe
        # WSL (Windows Subsystem for Linux)
        lua $script_path $target_dir | clip.exe
        echo "Files from '$target_dir' copied to clipboard (WSL)!"
    else
        echo "Error: No clipboard utility found (pbcopy, wl-copy, xclip, or clip.exe)."
        # Fallback: just print to screen
        lua $script_path $target_dir
    end
end
