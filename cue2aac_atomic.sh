#!/bin/bash
set -e
for cmd in cuebreakpoints shnsplit ffmpeg AtomicParsley; do
    if ! command -v "$cmd" &> /dev/null; then
        echo "Error: $cmd not found."
        exit 1
    fi
done
read -p "Enter CUE file name (or Enter to auto-detect): " cue_file
if [[ -z "$cue_file" ]]; then
    cue_file=$(ls *.cue 2>/dev/null | head -1)
    [[ -z "$cue_file" ]] && { echo "No .cue file found."; exit 1; }
    echo "Using: $cue_file"
fi
read -p "Enter FLAC file name (or Enter to auto-detect): " flac_file
if [[ -z "$flac_file" ]]; then
    flac_file=$(ls *.flac 2>/dev/null | head -1)
    [[ -z "$flac_file" ]] && { echo "No .flac file found."; exit 1; }
    echo "Using: $flac_file"
fi
echo "Splitting and encoding to AAC (256 kbps)..."
cuebreakpoints "$cue_file" | shnsplit -o "cust ext=m4a ffmpeg -i - -c:a aac -b:a 256k -movflags +faststart -y %f" -f "$cue_file" "$flac_file"
album=$(grep -m1 '^TITLE' "$cue_file" | sed 's/TITLE "\(.*\)"/\1/')
artist=$(grep -m1 '^PERFORMER' "$cue_file" | sed 's/PERFORMER "\(.*\)"/\1/')
year=$(grep -m1 '^REM DATE' "$cue_file" | sed 's/REM DATE "\(.*\)"/\1/')
genre=$(grep -m1 '^REM GENRE' "$cue_file" | sed 's/REM GENRE "\(.*\)"/\1/')
echo "Applying metadata and renaming..."
track_num=""
title=""
while IFS= read -r line; do
    line=$(echo "$line" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
    if [[ $line =~ ^TRACK[[:space:]]+([0-9]+) ]]; then
        if [[ -n "$track_num" && -n "$title" ]]; then
            track_dec=$((10#$track_num))
            src=$(printf "split-track%02d.m4a" "$track_dec")
            dst=$(printf "%02d - %s.m4a" "$track_dec" "$title")
            if [[ -f "$src" ]]; then
                echo "Tagging: $src -> $dst"
                AtomicParsley "$src" --overWrite --title "$title" --artist "$artist" --album "$album" --tracknum "$track_dec" --year "$year" --genre "$genre" --output "$dst" > /dev/null 2>&1
                rm "$src"
            fi
        fi
        track_num="${BASH_REMATCH[1]}"
        title=""
    elif [[ $line =~ ^TITLE[[:space:]]+\"(.+)\" ]]; then
        title="${BASH_REMATCH[1]//\//-}"
    fi
done < "$cue_file"
if [[ -n "$track_num" && -n "$title" ]]; then
    track_dec=$((10#$track_num))
    src=$(printf "split-track%02d.m4a" "$track_dec")
    dst=$(printf "%02d - %s.m4a" "$track_dec" "$title")
    if [[ -f "$src" ]]; then
        echo "Tagging: $src -> $dst"
        AtomicParsley "$src" --overWrite --title "$title" --artist "$artist" --album "$album" --tracknum "$track_dec" --year "$year" --genre "$genre" --output "$dst" > /dev/null 2>&1
        rm "$src"
    fi
fi
echo "Done! Tagged AAC files are ready."
