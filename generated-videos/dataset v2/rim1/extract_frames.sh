#!/usr/bin/env bash

mkdir -p frames

for video in *.mp4; do
    [ -e "$video" ] || continue

    name="${video%.mp4}"
    outdir="frames/$name"

    mkdir -p "$outdir"

    # Get total frame count
    total_frames=$(ffprobe -v error \
        -count_frames \
        -select_streams v:0 \
        -show_entries stream=nb_read_frames \
        -of csv=p=0 "$video")

    # Fallback if nb_read_frames is unavailable
    if [[ -z "$total_frames" || "$total_frames" == "N/A" ]]; then
        fps=$(ffprobe -v error \
            -select_streams v:0 \
            -show_entries stream=r_frame_rate \
            -of default=noprint_wrappers=1:nokey=1 "$video")

        duration=$(ffprobe -v error \
            -show_entries format=duration \
            -of default=noprint_wrappers=1:nokey=1 "$video")

        total_frames=$(python3 - <<EOF
from fractions import Fraction
fps = float(Fraction("$fps"))
duration = float("$duration")
print(int(fps * duration))
EOF
)
    fi

    echo "Processing $video ($total_frames frames)"

    # Extract 10 evenly spaced frames including first and last
    for i in $(seq 0 9); do
        frame_num=$(( i * (total_frames - 1) / 9 ))

        ffmpeg -v error \
            -i "$video" \
            -vf "select=eq(n\,$frame_num)" \
            -vframes 1 \
            "$outdir/frame_$(printf "%02d" $((i+1))).jpg"
    done
done