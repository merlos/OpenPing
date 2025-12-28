#!/bin/bash

# Video conversion script for App Store preview videos
# Converts from 1320x2868 to 886x1920 for App Store requirements

# Check if ffmpeg is installed
if ! command -v ffmpeg &> /dev/null; then
    echo "Error: ffmpeg is not installed."
    echo "Install it using: brew install ffmpeg"
    exit 1
fi

# Check if input file is provided
if [ $# -eq 0 ]; then
    echo "Usage: $0 <input_video_file> [output_file]"
    echo "Example: $0 screen_recording.mov app_preview.mov"
    exit 1
fi

INPUT_FILE="$1"
OUTPUT_FILE="${2:-${INPUT_FILE%.*}_converted.mov}"

# Check if input file exists
if [ ! -f "$INPUT_FILE" ]; then
    echo "Error: Input file '$INPUT_FILE' does not exist."
    exit 1
fi

echo "Converting '$INPUT_FILE' from 1320x2868 to 886x1920..."

# Convert video with App Store compatible settings (includes silent audio track)
ffmpeg -f lavfi -i anullsrc=channel_layout=stereo:sample_rate=48000 -i "$INPUT_FILE" \
    -vf "scale=886:1920:force_original_aspect_ratio=decrease,pad=886:1920:(ow-iw)/2:(oh-ih)/2:black" \
    -c:v libx264 \
    -r 30 \
    -profile:v baseline \
    -level 3.0 \
    -preset fast \
    -crf 23 \
    -maxrate 5000k \
    -bufsize 10000k \
    -c:a aac \
    -b:a 96k \
    -ar 48000 \
    -ac 2 \
    -shortest \
    -movflags +faststart \
    -pix_fmt yuv420p \
    -y "$OUTPUT_FILE"

if [ $? -eq 0 ]; then
    echo "✅ Conversion successful!"
    echo "Output file: $OUTPUT_FILE"
    
    # Display file info
    echo ""
    echo "Original file size: $(du -h "$INPUT_FILE" | cut -f1)"
    echo "Converted file size: $(du -h "$OUTPUT_FILE" | cut -f1)"
    
    # Get video dimensions to verify
    echo ""
    echo "Checking output dimensions..."
    ffprobe -v quiet -select_streams v:0 -show_entries stream=width,height -of csv=p=0 "$OUTPUT_FILE"
else
    echo "❌ Conversion failed!"
    exit 1
fi