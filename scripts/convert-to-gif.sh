#!/bin/bash

# Video to animated GIF conversion script
# Converts video files to high-quality animated GIFs

# Check if ffmpeg is installed
if ! command -v ffmpeg &> /dev/null; then
    echo "Error: ffmpeg is not installed."
    echo "Install it using: brew install ffmpeg"
    exit 1
fi

# Check if input file is provided
if [ $# -eq 0 ]; then
    echo "Usage: $0 <input_video_file> [output_file] [width] [fps]"
    echo "Example: $0 screen_recording.mov demo.gif 400 15"
    echo ""
    echo "Options:"
    echo "  width: Target width in pixels (default: 300)"
    echo "  fps: Frame rate (default: 2)"
    exit 1
fi

INPUT_FILE="$1"
OUTPUT_FILE="${2:-${INPUT_FILE%.*}.gif}"
WIDTH="${3:-300}"
FPS="${2:-2}"

# Check if input file exists
if [ ! -f "$INPUT_FILE" ]; then
    echo "Error: Input file '$INPUT_FILE' does not exist."
    exit 1
fi

echo "Converting '$INPUT_FILE' to animated GIF..."
echo "Settings: Width=${WIDTH}px, FPS=${FPS}"

# Create palette for better quality
PALETTE_FILE="/tmp/palette_$$.png"

echo "Generating color palette..."
ffmpeg -i "$INPUT_FILE" \
    -vf "fps=$FPS,scale=$WIDTH:-1:flags=lanczos,palettegen" \
    -y "$PALETTE_FILE" 2>/dev/null

if [ $? -ne 0 ]; then
    echo "❌ Palette generation failed!"
    exit 1
fi

echo "Converting to GIF..."
ffmpeg -i "$INPUT_FILE" -i "$PALETTE_FILE" \
    -filter_complex "fps=$FPS,scale=$WIDTH:-1:flags=lanczos[x];[x][1:v]paletteuse" \
    -y "$OUTPUT_FILE" 2>/dev/null

# Clean up palette file
rm -f "$PALETTE_FILE"

if [ $? -eq 0 ]; then
    echo "✅ Conversion successful!"
    echo "Output file: $OUTPUT_FILE"
    
    # Display file info
    echo ""
    echo "Original file size: $(du -h "$INPUT_FILE" | cut -f1)"
    echo "GIF file size: $(du -h "$OUTPUT_FILE" | cut -f1)"
    
    # Get GIF dimensions
    echo ""
    echo "Checking output dimensions..."
    ffprobe -v quiet -select_streams v:0 -show_entries stream=width,height -of csv=p=0 "$OUTPUT_FILE" 2>/dev/null
else
    echo "❌ Conversion failed!"
    exit 1
fi