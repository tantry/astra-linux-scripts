# normalize.sh – Loudness Normalization for Audio Files

Normalize the volume of audio files (`.m4a`, `.mp3`, `.flac`) to a consistent loudness level using FFmpeg’s EBU R128 loudnorm filter. This ensures that all tracks play back at a similar volume, without clipping or dynamic range compression.

## Scripts Overview

| File | Description |
|------|-------------|
| `normalize.sh` | One‑pass normalization (simpler, but may be less accurate for short files). |
| `two‑pass method` (see below) | More precise – extracts audio first, then applies loudnorm. |

Both scripts use the same target parameters:

- **Integrated loudness (`I`)** : `-16` LUFS (typical for streaming; lower = quieter, higher = louder)
- **True peak (`TP`)** : `-1.5` dBTP (prevents inter‑sample clipping)
- **Loudness range (`LRA`)** : `11` LU (preserves reasonable dynamics)

## Dependencies

- `ffmpeg` (with `libaac` or `fdk_aac` support)

Installation (Debian/Ubuntu):
```bash
sudo apt install ffmpeg
```

Arch/Manjaro:
```bash
sudo pacman -S ffmpeg
```

## Script 1: `normalize.sh` (One‑pass)

This script processes all `.m4a` files in the current directory, creating `normalized_*.m4a` files.

```bash
#!/bin/bash
for f in *.m4a; do
    echo "Processing: $f"
    ffmpeg -i "$f" -map 0:a:0 -af loudnorm=I=-16:TP=-1.5:LRA=11 -c:a aac -strict experimental "normalized_$f" -y 2>/dev/null
    echo "Finished: $f"
    echo "---"
done
echo "All done!"
```

### Usage

1. Place the script in a directory with your `.m4a` files.
2. Make it executable: `chmod +x normalize.sh`
3. Run it: `./normalize.sh`

### Notes

- The output files are prefixed with `normalized_`. To rename them back, run:
  ```bash
  for f in normalized_*.m4a; do mv "$f" "${f#normalized_}"; done
  ```
- Redirect `2>/dev/null` hides FFmpeg’s verbose output. Remove it to see details.
- The `-strict experimental` flag is rarely needed on modern FFmpeg.

## Script 2: Two‑pass method (more reliable)

For better accuracy (especially on short tracks), first extract the audio stream into a temporary file, then apply loudnorm. This also avoids re‑encoding the entire container.

**Save as `normalize_two_pass.sh`**:

```bash
#!/bin/bash
for f in *.m4a; do
    echo "Processing: $f"
    ffmpeg -i "$f" -vn -acodec copy temp.aac -y 2>/dev/null
    ffmpeg -i temp.aac -af loudnorm=I=-16:TP=-1.5:LRA=11 -c:a aac "normalized_$f" -y 2>/dev/null
    echo "Finished: $f"
    echo "---"
done
rm -f temp.aac
echo "All done!"
```

Then rename output files as above.

## Customising Loudness

| Change | Effect |
|--------|--------|
| `I=-14` | Louder (‑14 LUFS, typical for loud pop music) |
| `I=-18` | Quieter (‑18 LUFS, closer to classical/jazz) |
| `TP=-1.0` | Higher peak (risk of clipping on some players) |
| `TP=-2.0` | More headroom (safer but quieter peaks) |

## Batch Processing Other Formats

Replace `*.m4a` with:

- `*.mp3` (output to MP3 – adjust codec if needed)
- `*.flac` (output to FLAC – use `-c:a flac`)

Example for MP3:
```bash
for f in *.mp3; do
    ffmpeg -i "$f" -af loudnorm=I=-16:TP=-1.5:LRA=11 -c:a libmp3lame -b:a 192k "normalized_$f" -y
done
```

## Troubleshooting

| Problem | Possible cause | Solution |
|---------|----------------|----------|
| `aac codec not found` | FFmpeg compiled without AAC encoder | Use `-c:a libfdk_aac` or install `ffmpeg` from a repository with full features. |
| Output sounds distorted | True peak too high | Lower `TP` to `-2.0` or `-3.0`. |
| Very short files sound unchanged | Loudnorm needs enough audio for analysis | Use the two‑pass method or increase the `I` integration window. |
| Filename contains spaces | Script handles them correctly (quoted `"$f"`) | No action needed. |

## Repository

This script is part of my `astra_linux_scripts` collection. See other tools for FLAC+CUE splitting, metadata editing, and batch audio processing.

---

**Enjoy consistent volume across your music library!**
