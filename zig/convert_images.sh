#!/usr/bin/env bash
for filename in ./*.txt; do
  echo $filename
  convert -size 1000x1000 xc:white -font "FreeMono" -pointsize 8 -fill black -annotate +15+15 "@${filename}" \
    -trim -bordercolor "#FFF" -border 10 +repage "$(basename "$filename" .txt).png"
done
ffmpeg -framerate 30 -pattern_type glob -i '*.png' -c:v libx264 -pix_fmt yuv420p out.mp4
