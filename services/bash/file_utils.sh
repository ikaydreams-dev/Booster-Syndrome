#!/bin/bash

# File utility functions

# Check if file exists
file_exists() {
    [ -f "$1" ]
}

# Check if directory exists
dir_exists() {
    [ -d "$1" ]
}

# Create directory if not exists
ensure_dir() {
    [ ! -d "$1" ] && mkdir -p "$1"
}

# Get file size in bytes
file_size() {
    stat -f%z "$1" 2>/dev/null || stat -c%s "$1" 2>/dev/null
}

# Get file extension
get_extension() {
    echo "${1##*.}"
}

# Get filename without extension
get_basename() {
    local filename="${1##*/}"
    echo "${filename%.*}"
}

# Count lines in file
count_lines() {
    wc -l < "$1" | tr -d ' '
}

# Find files by extension
find_by_extension() {
    local dir="$1"
    local ext="$2"
    find "$dir" -type f -name "*.$ext"
}

# Backup file
backup_file() {
    local file="$1"
    local backup="${file}.backup.$(date +%Y%m%d_%H%M%S)"
    cp "$file" "$backup"
    echo "$backup"
}

# Remove old files
cleanup_old_files() {
    local dir="$1"
    local days="$2"
    find "$dir" -type f -mtime +${days} -delete
}

# Get file modification time
get_mtime() {
    stat -f%m "$1" 2>/dev/null || stat -c%Y "$1" 2>/dev/null
}

# Compare files
files_are_same() {
    diff -q "$1" "$2" > /dev/null
}

# Create temp file
create_temp_file() {
    mktemp
}

# Create temp directory
create_temp_dir() {
    mktemp -d
}
