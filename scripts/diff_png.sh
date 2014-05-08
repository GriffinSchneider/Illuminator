#!/bin/sh

mycmd=$(basename $0)
if [ $# -lt 4 ]
then
  echo
  echo "Usage: $mycmd <file1> <file2> <mask> <diff>"
  echo
  echo "Compare two images and print the number of pixels that differ."
  echo "  - mask is a transparent image with masked areas colored magenta"
  echo "  - diff image will be written to the given basename in PNG and GIF format"
  echo
  exit 2;
fi

echo "Create temp image files" >&2
# FIXME: need PNG extensions!!!
tmpdir=$(mktemp -dt "$mycmd.")
img1="$tmpdir/img1.png"
img2="$tmpdir/img2.png"
imgm="$tmpdir/imgm.png"

echo "Normalize mask to black" >&2
convert "$3" -fill black -opaque magenta "$imgm"
echo "Apply mask to image 1" >&2
composite -gravity center "$3" "$1" "$img1"
echo "Apply mask to image 2" >&2
composite -gravity center "$3" "$2" "$img2"

echo "Compare 2 masked images, get differences" >&2
diffpixels=$(compare "$img1" "$img2" -highlight-color red -metric AE "$4.png" 2>&1)
RESULT=$?
echo "Re-overlay the mask on the composite" >&2
composite -gravity center "$imgm" "$4.png" "$4.png"

# IF DIFFERENT
if [ "$diffpixels" -ne "0" ]
then
    echo "Create the animated gif comparison" >&2
    convert -delay 50 "$img1" "$img2" -loop 0 "$4.gif"
fi

# count total pixels
convert compared.png -print "pixels (total): %[fx:w*h]\n" null:

# count masked pixels
convert "$3" -format %c histogram:info: | grep FF00FF | tr -d ' ' | awk -F: '{print "pixels masked: " $1}'

# count changed pixels
echo "pixels changed: $diffpixels"

# remove temp images
rm -rf "$tmpdir"