## `README.md`

```markdown
# cue2aac: Split FLAC+CUE to Tagged AAC Tracks

Convert a single FLAC audio file (with a companion CUE sheet) into individual AAC (`.m4a`) tracks, with metadata and file names taken from the CUE sheet.

## The Script

**File:** `cue2aac_atomic.sh`

This bash script:
1. Splits the FLAC image according to the CUE sheet.
2. Encodes each track to AAC at 256 kbps (`.m4a` container).
3. Embeds metadata (title, artist, album, track number, year, genre) using `AtomicParsley`.
4. Renames the files to `01 - Song Title.m4a`.

It is robust – it handles track numbers with leading zeros (`08`, `09`) correctly.

## Dependencies

Install the following tools before running the script:

| Tool | Purpose | Installation (Debian/Ubuntu) | Installation (Arch/Manjaro) |
|------|---------|------------------------------|-----------------------------|
| `shntool` | Splitting | `sudo apt install shntool` | `sudo pacman -S shntool` |
| `cuetools` | Provides `cuebreakpoints` | `sudo apt install cuetools` | `sudo pacman -S cuetools` |
| `ffmpeg` | Audio encoding | `sudo apt install ffmpeg` | `sudo pacman -S ffmpeg` |
| `AtomicParsley` | M4A tagging | `sudo apt install atomicparsley` | `sudo pacman -S atomicparsley` |

> **Note:** On some distributions `cuetools` may install `cuetag` instead of `cuetag.sh` – the script does not use them; it uses `AtomicParsley` for tagging.

## Usage

1. Place the script in the same directory as your `.cue` and `.flac` files (or anywhere in your `$PATH`).
2. Make it executable:
   ```bash
   chmod +x cue2aac_atomic.sh
   ```
3. Run the script:
   ```bash
   ./cue2aac_atomic.sh
   ```
4. Follow the prompts:
   - Enter the CUE file name (e.g., `album.cue`) – or press Enter to auto‑detect.
   - Enter the FLAC file name (e.g., `album.flac`) – or press Enter to auto‑detect.

The script will produce files named like `01 - First Track.m4a`, `02 - Second Track.m4a`, etc., fully tagged.

## Example

```bash
$ ls
'02. Andres Segovia – My Favourite Works (1987).cue'
'01. Andres Segovia - My Favorite Works (1987).flac'

$ ./cue2aac_atomic.sh
Enter CUE file name (or Enter to auto-detect):
Using: 02. Andres Segovia – My Favourite Works (1987).cue
Enter FLAC file name (or Enter to auto-detect):
Using: 01. Andres Segovia - My Favorite Works (1987).flac
Splitting and encoding to AAC (256 kbps)...
Applying metadata and renaming...
Tagging: split-track01.m4a -> 01 - Three pieces for lute: Allemande.m4a
Tagging: split-track02.m4a -> 02 - Three pieces for lute: Sarabande.m4a
...
Done! Tagged AAC files are ready.
```

## How It Works

- `cuebreakpoints` extracts the track split positions from the CUE file.
- `shnsplit` pipes the raw audio to `ffmpeg`, which encodes each chunk to AAC (256 kbps) and saves as `split-trackNN.m4a`.
- The script then parses the CUE file for track titles and global metadata (artist, album, year, genre).
- `AtomicParsley` writes the metadata to each `.m4a` file and renames it to `NN - Title.m4a`.
- The temporary `split-track*.m4a` files are deleted.

## Troubleshooting

| Problem | Likely cause | Solution |
|---------|--------------|----------|
| `shnsplit: unsupported format 0xfffe` | High‑resolution FLAC with modern header. | Use the alternative tool `ffcuesplitter` (see below). |
| `AtomicParsley: command not found` | `atomicparsley` not installed. | Install it with your package manager (see Dependencies). |
| `printf: 08: invalid octal number` | An old version of the script; update to the one above. | The current script uses `$((10#$track_num))` to force decimal conversion. |
| `ERROR: Invalid CUE sheet file` | The CUE file name contains a typo or mismatched quotes. | Use tab completion to enter the exact name, or let the script auto‑detect. |

## Alternative Tool: `ffcuesplitter`

If you prefer to keep the lossless FLAC format (or need to split files with the `0xfffe` error), you can use `ffcuesplitter`:

1. Install it via `pipx` or in a virtual environment:
   ```bash
   pipx install ffcuesplitter
   ```
2. Run:
   ```bash
   ffcuesplitter -i "your.cue" -f flac
   ```
   This outputs individual FLAC tracks without re‑encoding.

> Note: `ffcuesplitter` supports `wav`, `flac`, `mp3`, `ogg`, `opus` but **not** AAC directly. To get AAC from its output, convert afterwards with `ffmpeg`.

## License

Feel free to use, modify, and distribute this script. No warranty.

## Repository

This script is part of my collection of useful Linux tools. See [GitHub link] for more.
```
