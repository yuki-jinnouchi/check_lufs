#!/bin/bash

# Output file
output_file="lufs_results.txt"

# Check if directory is provided as an argument
if [ -z "$1" ]; then
    echo "Usage: $0 <directory>"
    exit 1
fi

# Get the directory from the argument
directory="$1"

# Function to check LUFS
check_lufs() {
    file="$1"
    result=$(ffmpeg -i "$file" -af ebur128=framelog=verbose -f null - 2>&1)
    echo "$result" | grep -oE 'I:\s*-?[0-9]+(\.[0-9]+)? LUFS' | awk '{print $2}' | tail -n 1
}

# Function to format file name
format_file_name() {
    file_name=$(basename "$1")
    max_length=32
    truncated_file_name=$(echo "$file_name" | cut -c1-$max_length)

    # Check if the file name was truncated
    if [ "${#file_name}" -gt "$max_length" ]; then
        echo "${truncated_file_name}..."
    else
        echo -n "$file_name"
        printf '%*s' $((32+3 - ${#file_name})) ''
    fi
}

# Initialize the output file
echo "LUFS Results" > "$output_file"
echo "============" >> "$output_file"
echo "" >> "$output_file"

# Loop over all audio files in the specified directory
find "$directory" -type f \( \
        -iname "*.mp3" \
        -o -iname "*.wav" \
        -o -iname "*.flac" \
        -o -iname "*.aac" \
        -o -iname "*.ogg" \) | while read -r file; do
    lufs=$(check_lufs "$file")
    if [[ -z "$lufs" ]]; then
        lufs="N/A"
    fi
    formatted_file_name=$(format_file_name "$file")

    # Ensure the file name is truncated to 64 characters for alignment
    padding=""
    if [ ${#formatted_file_name} -lt 32 ]; then
        padding=$(printf '%*s' $((32 - ${#formatted_file_name})) '')
    fi

    # Print the result, ensuring proper alignment
    printf "File: %s%s Integrated LUFS: %s\n" "$formatted_file_name" "$padding" "$lufs" >> "$output_file"
done

# Inform the user
echo "LUFS results have been saved to $output_file"
