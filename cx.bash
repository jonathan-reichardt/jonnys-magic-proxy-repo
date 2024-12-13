# The cx command
cx() {
    # If no argument is provided, just `cd` to home
    if [ $# -eq 0 ]; then
        cd
        return
    fi

    # Gather directories in current dir
    local dirs=(*/)
    if [ ${#dirs[@]} -eq 0 ]; then
        # No directories: just try normal cd
        cd "$1" 2>/dev/null || {
            echo "No directories here and '$1' is not a valid directory."
            return 1
        }
        return
    fi

    dirs=("${dirs[@]%/}")  # Strip trailing slashes

    # Find common prefix
    local prefix="${dirs[0]}"
    for d in "${dirs[@]}"; do
        local new_prefix=""
        for (( i=0; i<${#prefix} && i<${#d}; i++ )); do
            if [ "${prefix:$i:1}" = "${d:$i:1}" ]; then
                new_prefix="${new_prefix}${prefix:$i:1}"
            else
                break
            fi
        done
        prefix="$new_prefix"
        [ -z "$prefix" ] && break
    done

    # Try prefix + argument
    local target="${prefix}${1}"

    if [ -d "$target" ]; then
        cd "$target"
    else
        # Fallback to normal cd if no match
        if cd "$1" 2>/dev/null; then
            return
        else
            echo "No directory found for '$1' with prefix '$prefix'."
            return 1
        fi
    fi
}

# Completion function for cx
_cx() {
    # Current word being completed
    local cur prev
    COMPREPLY=()
    # Use bash completion internals to get current word
    _get_comp_words_by_ref cur prev

    # Gather directories
    local dirs=(*/)
    dirs=("${dirs[@]%/}")

    # If no directories, no completion
    [ ${#dirs[@]} -eq 0 ] && return 0

    # Find the common prefix of all directories
    local prefix="${dirs[0]}"
    for d in "${dirs[@]}"; do
        local new_prefix=""
        for (( i=0; i<${#prefix} && i<${#d}; i++ )); do
            if [ "${prefix:$i:1}" = "${d:$i:1}" ]; then
                new_prefix="${new_prefix}${prefix:$i:1}"
            else
                break
            fi
        done
        prefix="$new_prefix"
        [ -z "$prefix" ] && break
    done

    # Generate a list of suffixes by stripping the common prefix
    local suffixes=()
    for d in "${dirs[@]}"; do
        # Only consider it a valid suffix if prefix is indeed a prefix of d
        if [[ "$d" == "$prefix"* ]]; then
            local suffix="${d#$prefix}"
            suffixes+=("$suffix")
        fi
    done

    # Use compgen to match user-typed prefix (cur) against our suffixes
    COMPREPLY=( $(compgen -W "${suffixes[*]}" -- "$cur") )

    return 0
}

# Enable completion for cx
complete -F _cx cx
