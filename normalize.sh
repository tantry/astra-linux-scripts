#!/bin/bash
for f in *.m4a; do
    echo "Processing: $f"
    ffmpeg -i "$f" -map 0:a:0 -af loudnorm=I=-16:TP=-1.5:LRA=11 -c:a aac -strict experimental "normalized_$f" -y 2>/dev/null
    echo "Finished: $f"
    echo "---"
done
echo "All done!"
