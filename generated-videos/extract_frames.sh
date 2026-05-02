#!/usr/bin/env bash
set -euo pipefail

# Usage: ./extract_frames.sh [num_frames]
# Default: 4 frames per video
# Places output in generated-videos/frames/<video_basename>/<video_basename>_01.jpg ...

N_FRAMES=${1:-4}

if ! command -v ffmpeg >/dev/null 2>&1; then
  echo "ffmpeg not found in PATH. Install ffmpeg and try again." >&2
  exit 1
fi
if ! command -v ffprobe >/dev/null 2>&1; then
  echo "ffprobe not found in PATH. Install ffmpeg (ffprobe) and try again." >&2
  exit 1
fi

SCRIPT_DIR="$2"
INPUT_DIR="$SCRIPT_DIR"
OUTPUT_ROOT="$SCRIPT_DIR/frames"
mkdir -p "$OUTPUT_ROOT"

shopt -s nullglob
exts=(mp4 mov mkv avi webm mpg mpeg)
for ext in "${exts[@]}"; do
  for file in "$INPUT_DIR"/*."$ext"; do
    [ -f "$file" ] || continue
    filename=$(basename -- "$file")
    base="${filename%.*}"
    outdir="$OUTPUT_ROOT/$base"
    mkdir -p "$outdir"
    echo "Processing $filename -> $outdir (extracting $N_FRAMES frames)"
    duration=$(ffprobe -v error -select_streams v:0 -show_entries format=duration -of csv=p=0 "$file")
    if [[ -z "$duration" ]]; then
      echo "  Could not determine duration for $filename, skipping" >&2
      continue
    fi
    for i in $(seq 1 "$N_FRAMES"); do
      fraction=$(awk -v i="$i" -v n="$N_FRAMES" 'BEGIN{printf "%.6f", i/(n+1)}')
      timestamp=$(awk -v d="$duration" -v f="$fraction" 'BEGIN{printf "%.3f", d*f}')
      out="$outdir/${base}_$(printf "%02d" "$i").jpg"
      ffmpeg -hide_banner -loglevel error -ss "$timestamp" -i "$file" -frames:v 1 -q:v 2 "$out" || echo "  Failed to extract frame $i from $filename" >&2
    done
  done
done

echo "Done. Frames are in $OUTPUT_ROOT"
