#!/bin/bash

# Use first argument as base directory, default to current directory
base_dir="${1:-.}"

# Ensure base_dir is absolute
cd "$base_dir" || exit 1
base_dir=$(pwd)

# Now perform the same logic
find . -mindepth 1 -type d | while read -r dir; do
    files=$(find "$dir" -maxdepth 1 -type f | sort)

    if [ "$(echo "$files" | wc -l)" -eq 10 ]; then
        output_file="$dir/files.txt"
        echo "$files" | sed 's|^\./||' > "$output_file"
        echo "Wrote: $output_file"
    fi
done
