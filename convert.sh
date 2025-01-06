#!/bin/bash

# Check if directory argument is provided
if [ -z "$1" ]; then
  echo "Usage: $0 /path/to/folder"
  exit 1
fi

# Assign the specified directory
DIR="$1"

# Check if the directory exists
if [ ! -d "$DIR" ]; then
  echo "Error: Directory '$DIR' does not exist."
  exit 1
fi

# Loop through all FLAC files in the directory
for file in "$DIR"/*.flac; do
  # Skip if no FLAC files are found
  [ -e "$file" ] || continue
  
  # Get the base name without extension
  base=$(basename "$file" .flac)

  # Convert FLAC to MP3 with the same name
  ffmpeg -i "$file" -q:a 2 "$DIR/$base.mp3"

  # Print status
  echo "Converted: $file -> $DIR/$base.mp3"
done

echo "All FLAC files converted to MP3!"
