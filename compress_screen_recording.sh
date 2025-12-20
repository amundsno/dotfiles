#!/bin/bash

set -e

output_dir="$HOME/Desktop/Screen Recordings/Curated"
input_dir="$HOME/Desktop/Screen Recordings/Raw"

# Initialize variables
output_name=""
trim_start=""
trim_end=""
selected_file=""

# Parse command line arguments
while getopts "n:s:e:h" opt; do
  case $opt in
    n)
      output_name="$OPTARG"
      ;;
    s)
      trim_start="$OPTARG"
      ;;
    e)
      trim_end="$OPTARG"
      ;;
    h)
      echo "Usage: $0 [-n output_name] [-s trim_start_seconds] [-e trim_end_seconds]"
      echo "  -n: Output filename (without extension)"
      echo "  -s: Seconds to trim from the start"
      echo "  -e: Seconds to trim from the end"
      echo "  -h: Show this help message"
      exit 0
      ;;
    \?)
      echo "Invalid option: -$OPTARG" >&2
      echo "Use -h for help"
      exit 1
      ;;
  esac
done

# Check if gum is available
if ! command -v gum &> /dev/null; then
    echo "Warning: 'gum' is not installed. Using default values for missing options."
    echo "Install with: brew install gum"
fi

# Change to input directory
if [[ ! -d "$input_dir" ]]; then
    echo "Error: Input directory does not exist: $input_dir"
    exit 1
fi

cd "$input_dir" || exit

# Select file interactively if not specified
if command -v gum &> /dev/null; then
    selected_file=$(ls -t | gum choose --header "Select a recording to compress...")
    if [[ -z "$selected_file" ]]; then
        echo "No file selected. Exiting."
        exit 1
    fi
else
    # Fallback to latest recording
    selected_file=$(ls -t | head -n 1)
    echo "Using latest recording: $selected_file"
fi

# Validate that file exists
if [[ ! -f "$selected_file" ]]; then
    echo "Error: Selected file does not exist: $selected_file"
    exit 1
fi

echo "Selected file: $selected_file"

# Get output name interactively if not specified
if [[ -z "$output_name" ]]; then
    if command -v gum &> /dev/null; then
        output_name=$(gum input --placeholder "Enter output filename (without extension)...")
        if [[ -z "$output_name" ]]; then
            echo "No output name provided. Exiting."
            exit 1
        fi
    else
        # Use input filename without extension as fallback
        output_name="${selected_file%.*}_compressed"
        echo "Using output name: $output_name"
    fi
fi

# Validate output name (no slashes, not empty)
if [[ "$output_name" =~ [/\\] ]]; then
    echo "Error: Output name cannot contain slashes"
    exit 1
fi

echo "Output file: $output_name"

# Get trim values interactively if not specified and gum is available
if [[ -z "$trim_start" ]] && command -v gum &> /dev/null; then
    trim_start=$(gum input --placeholder "Seconds to trim from start (leave empty to skip)...")
fi

# Set defaults if still empty
trim_start="${trim_start:-0}"

# Validate trim values are numbers
if ! [[ "$trim_start" =~ ^[0-9]+(\.[0-9]+)?$ ]]; then
    echo "Error: Start trim value must be a number: $trim_start"
    exit 1
fi

echo "Seconds to trim from start: $trim_start"

if [[ -z "$trim_end" ]] && command -v gum &> /dev/null; then
    trim_end=$(gum input --placeholder "Seconds to trim from end (leave empty to skip)...")
fi


trim_end="${trim_end:-0}"

if ! [[ "$trim_end" =~ ^[0-9]+(\.[0-9]+)?$ ]]; then
    echo "Error: End trim value must be a number: $trim_end"
    exit 1
fi


echo "Seconds to trim from end: $trim_start"

# Create output directory if it doesn't exist
mkdir -p "$output_dir"

# Build ffmpeg command
ffmpeg_cmd="ffmpeg -i \"$selected_file\""

# Add trim from start if specified
if (( $(echo "$trim_start > 0" | bc -l) )); then
    ffmpeg_cmd="$ffmpeg_cmd -ss $trim_start"
fi

# Calculate duration if trimming from end
if (( $(echo "$trim_end > 0" | bc -l) )); then
    # Get total duration of the video
    duration=$(ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "$selected_file")
    new_duration=$(echo "$duration - $trim_start - $trim_end" | bc -l)
    
    if (( $(echo "$new_duration <= 0" | bc -l) )); then
        echo "Error: Trim values exceed video duration"
        exit 1
    fi
    
    ffmpeg_cmd="$ffmpeg_cmd -t $new_duration"
fi

ffmpeg_cmd="$ffmpeg_cmd -c:v libx264 -preset medium -crf 23 -c:a aac -b:a 128k \"$output_dir/$output_name.mp4\""

# Execute ffmpeg command
echo "Compressing video..."
eval $ffmpeg_cmd

echo "✓ Compression complete: $output_dir/$output_name.mp4"
open "$output_dir"
