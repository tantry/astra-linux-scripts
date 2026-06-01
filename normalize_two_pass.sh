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