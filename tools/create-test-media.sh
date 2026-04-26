#!/bin/bash
# Generate minimal stub media files for the Plex integration test server.
# Requires ffmpeg. On macOS: brew install ffmpeg
# Output goes to ./plex-test-data/media (or $1 if provided).
set -eu

MEDIA_DIR="${1:-plex-test-data/media}"

if ! command -v ffmpeg &>/dev/null; then
    echo "ERROR: ffmpeg not found. Install it first (brew install ffmpeg / apt install ffmpeg)." >&2
    exit 1
fi

FFMPEG="ffmpeg -y -loglevel error"
VIDEO_ARGS="-f lavfi -i color=c=black:s=320x240:r=1 -f lavfi -i anullsrc=r=44100:cl=stereo -t 1 -vcodec libx264 -acodec aac"
AUDIO_ARGS="-f lavfi -i anullsrc=r=44100:cl=mono -t 1 -acodec libmp3lame -q:a 9"

make_video() {
    local path="$1"
    [ -f "$path" ] && return
    mkdir -p "$(dirname "$path")"
    $FFMPEG $VIDEO_ARGS "$path"
    echo "  created: $path"
}

make_audio() {
    local path="$1"
    [ -f "$path" ] && return
    mkdir -p "$(dirname "$path")"
    $FFMPEG $AUDIO_ARGS "$path"
    echo "  created: $path"
}

echo "==> Movies"
make_video "$MEDIA_DIR/Movies/Big Buck Bunny (2008).mp4"
make_video "$MEDIA_DIR/Movies/Sintel (2010).mp4"
make_video "$MEDIA_DIR/Movies/Elephants Dream (2006).mp4"
make_video "$MEDIA_DIR/Movies/Sita Sings the Blues (2008).mp4"

echo "==> TV Shows"
for EP in \
    "Game of Thrones/S01E01" \
    "Game of Thrones/S01E02" \
    "Game of Thrones/S01E03" \
    "Game of Thrones/S02E01" \
    "Game of Thrones/S02E02" \
    "The 100/S01E01" \
    "The 100/S01E02" \
    "The 100/S01E03" \
    "The 100/S02E01"
do
    make_video "$MEDIA_DIR/TV Shows/$EP.mp4"
done

echo "==> Music"
make_audio "$MEDIA_DIR/Music/Broke for Free/Layers/01 - As Colorful As Ever.mp3"
make_audio "$MEDIA_DIR/Music/Broke for Free/Layers/02 - Knock Knock.mp3"
make_audio "$MEDIA_DIR/Music/Broke for Free/Layers/03 - Only Knows.mp3"

echo "Done. Stub media ready in $MEDIA_DIR"
