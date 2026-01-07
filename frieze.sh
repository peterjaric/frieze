#!/bin/bash
# shellcheck disable=SC1090

# Exit immediately on various errors
set -eo pipefail

COMMAND=$1
SCRIPT_DIR="$(dirname "$0")"

# shellcheck disable=SC1091
source "$SCRIPT_DIR/config.env"

# Read API keys if available
if [[ -f "$KEY_FILE" ]]; then
  source "$KEY_FILE"
fi

# Get API functions
source "$SCRIPT_DIR/$TEXT_SCRIPT"
source "$SCRIPT_DIR/$IMAGE_SCRIPT"


NUMBER_OF_SUGGESTIONS=five
PROMPT_GENERATION_IMAGE_PROMPT="I need a motif for an AI image generation task. The image will be displayed at the top of a newly started terminal. Please provide $NUMBER_OF_SUGGESTIONS creative and unique motifs which can be used to generate interesting images in an array. Express the motifs in at most five words."
PROMPT_GENERATION_SLOGAN_PROMPT="Please suggest $NUMBER_OF_SUGGESTIONS creative and unique hacker, programmer, sci-fi, tech, steam-punk or fantasy slogans. The text will be displayed at the top of a newly started terminal. Express the slogans in at most five words."
PROMPT_GENERATION_STYLE_PROMPT="Please suggest $NUMBER_OF_SUGGESTIONS unique art or fashion styles. Be creative, don't fall back on the cliches. Express the styles in two to three words each."

link_random_existing_image() {
    # shellcheck disable=SC2207
    local existing_images=($(ls "$IMAGE_FOLDER/design_*.png" 2>/dev/null))
    if [[ ${#existing_images[@]} -gt 0 ]]; then
      # Pick a random existing image
      random_image=${existing_images[$RANDOM % ${#existing_images[@]}]}
      ln -sf "$random_image" "$IMAGE_FOLDER/latest.png"
    fi
}

log() {
  local message="$1"
  echo "$(date '+%Y-%m-%d %H:%M:%S') - $message" >> /tmp/frieze.log
}

generate_banner_image() {
  # Check that jq is installed
  if ! command -v jq &> /dev/null; then
    echo "jq is not installed, please install it."
    return 1
  fi

  cd /tmp || { echo "Hello World!"; return 0; }

  local text
  # shellcheck disable=SC2034
  text=$(get_text "$PROMPT_GENERATION_SLOGAN_PROMPT")
  log "Generated slogan: $text"

  local design
  # shellcheck disable=SC2034
  design=$(get_text "$PROMPT_GENERATION_IMAGE_PROMPT")
  log "Generated design motif: $design"

  local style
  # shellcheck disable=SC2034
  style=$(get_text "$PROMPT_GENERATION_STYLE_PROMPT")
  log "Generated style: $style"

  local index=$((RANDOM % ${#PROMPT_TEMPLATES[@]}))
  local prompt
  prompt=$(eval echo "${PROMPT_TEMPLATES[$index]}")

  log "Generated prompt: $prompt"

  local image_url
  image_url=$(get_image_url "$prompt")

  log "Image URL: $image_url"

  # If we hit the rate limit, pick a random existing image
  if [[ -z "$image_url" || "$image_url" == "null" ]]; then
    log "Image URL is empty or null."
    link_random_existing_image
  fi

  # Download the image
  local prompt_as_filename
  prompt_as_filename=$(echo "$prompt" | tr -d '[:punct:]' | tr ' ' '_')
  local image_name=design_"$prompt_as_filename".png

  curl -s -o "$image_name" "$image_url"
  # Check that the image was downloaded and is a valid image
  if ! "$MAGICK_COMMAND" identify "$image_name" &> /dev/null; then
    log "Invalid image downloaded from: $image_url"
    link_random_existing_image
  else
    mkdir -p "$IMAGE_FOLDER"
    "$MAGICK_COMMAND" "$image_name" -fuzz 10% -trim +repage "$IMAGE_FOLDER/$image_name"
    ln -sf "$IMAGE_FOLDER/$image_name" "$IMAGE_FOLDER/latest.png"
    log "Image saved to $IMAGE_FOLDER/$image_name"
  fi

}

display_banner_image() {
  local resolution="$1"
  local filename="$2"
  local height=$DEFAULT_HEIGHT

  if [[ -z "$filename" ]]; then
    filename="$IMAGE_FOLDER/latest.png"
  fi

  if [[ ! -f "$filename" ]]; then
    echo "$0: Image file $filename does not exist. Run '$0 generate' first."
    return 1
  fi

  # Make sure the terminal size variables are set, even when clearing the screen
  # https://stackoverflow.com/questions/263890/how-do-i-find-the-width-height-of-a-terminal-window#comment78184101_563592
  shopt -s checkwinsize; (:);

  local width=$COLUMNS
  if [[ -z "$width" ]]; then
    width=$DEFAULT_WIDTH
  fi

  # Check if we should try to display high def images and if so, if we are running in WEZTERM
  if [[ "$resolution" == "high" && -n "$WEZTERM_EXECUTABLE" ]]; then
    wezterm imgcat --width "$width" "$filename"
  else
    # Check that tiv is installed
    if ! command -v tiv &> /dev/null; then
      echo "tiv is not installed. Install it from https://github.com/stefanhaustein/TerminalImageViewer?tab=readme-ov-file"
      return 1
    fi
    tiv -w "$width" -h "$height" "$filename"
  fi
}

print_info() {
  echo "Configuration:"
  echo "  IMAGE_FOLDER        $IMAGE_FOLDER"
  echo "  TEXT_SCRIPT         $TEXT_SCRIPT"
  echo "  IMAGE_SCRIPT        $IMAGE_SCRIPT"
  echo "Images:"
  if [[ -f "$IMAGE_FOLDER/latest.png" ]]; then
    echo -n "  Latest:             "
    basename "$(readlink "$IMAGE_FOLDER/latest.png")"
    echo "  Generated images:   $(ls "$IMAGE_FOLDER"/design_*.png 2>/dev/null | wc -l)"
  else
    echo "  No image generated yet."
  fi
}

# Make sure everything is set up
mkdir -p "$IMAGE_FOLDER"
# Check that magick is installed
MAGICK_COMMAND=magick
if ! command -v magick &> /dev/null; then
  MAGICK_COMMAND=convert
  if ! command -v convert &> /dev/null; then
    echo "Neither magick nor convert is installed. Please install ImageMagick."
    return 1
  fi
fi
if [[ ! -f "$IMAGE_FOLDER/latest.png" ]]; then
  # Create a placeholder image until one is generated
  "$MAGICK_COMMAND" -size 2048x256 xc:red -gravity center -pointsize 170 -fill grey -annotate +0+0 "No frieze generated yet" "$IMAGE_FOLDER/design_first.png"
  ln -sf "$IMAGE_FOLDER/design_first.png" "$IMAGE_FOLDER/latest.png"
fi

if [[ "$COMMAND" == "generate" ]]; then
  set +m # Disable job control, so that the generate command does not produce job control messages.
  generate_banner_image &
elif [[ "$COMMAND" == "display" ]]; then
  resolution="$2"
  filename="$3"
  display_banner_image "$resolution" "$filename"
elif [[ "$COMMAND" == "info" ]]; then
  print_info
else
  echo "Usage: $0 generate|display [<low|high> [<filename>]]|info|usage"
  exit 1
fi
