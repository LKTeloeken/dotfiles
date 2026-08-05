function rename-component
    if test (count $argv) -ne 3
        echo "Usage: rename-component <path> <old_name> <new_name>"
        return 1
    end
    
    set target_path $argv[1]
    set old_name $argv[2]
    set new_name $argv[3]
    
    set folder "$target_path/$old_name"

    if not test -d "$folder"
        echo "Error: folder '$folder' does not exist"
        return 1
    end

    for f in "$folder"/"$old_name".*
        set base (basename "$f")
        set suffix (string replace -r "^$old_name" "" "$base")
        mv -- "$f" "$folder/$new_name$suffix"
    end

    mv -- "$folder" "$target_path/$new_name"

    echo "Renamed '$old_name' to '$new_name' in '$target_path'"
end
