#!/usr/bin/env bash
# shellcheck disable=SC1117

readonly SCRIPT=$(basename "$0")
readonly VERSION='0.4.0'
readonly RESOLUTIONS=(1920x1200 1920x1080 800x480 400x240)

usage() {
cat <<EOF
Usage:
  $SCRIPT [options]
  $SCRIPT -h | --help
  $SCRIPT --version

Options:
  -f --force                     Force download of picture. This will overwrite
                                 the picture if the filename already exists.
  -s --ssl                       Communicate with bing.com over SSL.
  -q --quiet                     Do not display log messages.
  -n --filename <file name>      The name of the downloaded picture. Defaults to
                                 the upstream name.
  -p --picturedir <picture dir>  The full path to the picture download dir.
                                 Will be created if it does not exist.
                                 [default: $HOME/Pictures/bing-wallpapers/]
  -r --resolution <resolution>   The resolution of the image to retrieve.
                                 Supported resolutions: ${RESOLUTIONS[*]}
  -w --set-wallpaper             Set downloaded picture as wallpaper (Only mac support for now).
  -h --help                      Show this screen.
  --version                      Show version.
EOF
}

print_message() {
    if [ ! "$QUIET" ]; then
        printf "%s\n" "${1}"
    fi
}

# Defaults
PICTURE_DIR="$HOME/Pictures/bing-wallpapers/"
RESOLUTION="1920x1080"

# Option parsing
while [[ $# -gt 0 ]]; do
    key="$1"

    case $key in
        -r|--resolution)
            RESOLUTION="$2"
            shift
            ;;
        -p|--picturedir)
            PICTURE_DIR="$2"
            shift
            ;;
        -n|--filename)
            FILENAME="$2"
            shift
            ;;
        -f|--force)
            FORCE=true
            ;;
        -s|--ssl)
            SSL=true
            ;;
        -q|--quiet)
            QUIET=true
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        -w|--set-wallpaper)
            SET_WALLPAPER=true
            ;;
        --version)
            printf "%s\n" $VERSION
            exit 0
            ;;
        *)
            (>&2 printf "Unknown parameter: %s\n" "$1")
            usage
            exit 1
            ;;
    esac
    shift
done

# Set options
[ $QUIET ] && CURL_QUIET='-s'
[ $SSL ]   && PROTO='https'   || PROTO='http'

# Create picture directory if it doesn't already exist
mkdir -p "${PICTURE_DIR}"

# Parse bing.com and acquire picture URL(s)
read -ra urls < <(curl -sL "https://www.bing.com/HPImageArchive.aspx?format=xml&idx=0&n=1" | grep -Eo "<url>(.*)</url>" | sed -e "s/<url>\([^’]*\)\<\/url>/\1/")


for p in "${urls[@]}"; do
    if [ -z "$FILENAME" ]; then
        filename=$(date +"%m-%d-%y").jpg
    else
        filename="$FILENAME"
    fi
    if [ $FORCE ] || [ ! -f "$PICTURE_DIR/$filename" ]; then
        print_message "Downloading: $filename..."
        curl $CURL_QUIET -Lo "$PICTURE_DIR/$filename" "http://bing.com$p"
    else
        print_message "Skipping: $filename..."
    fi
done

if [ $SET_WALLPAPER ]; then
    /usr/bin/osascript<<END
tell application "System Events" to set picture of every desktop to ("$PICTURE_DIR/$filename" as POSIX file as alias)
END
fi
