#!/bin/bash
# shellcheck disable=SC1090

COMMAND=$1
SCRIPT_DIR="$(dirname "$0")"

source "$SCRIPT_DIR/config.env"

# Read API keys
source "$KEY_FILE"

# Get API functions
source "$SCRIPT_DIR/$TEXT_SCRIPT"
source "$SCRIPT_DIR/$IMAGE_SCRIPT"


NUMBER_OF_SUGGESTIONS=five
PROMPT_GENERATION_IMAGE_PROMPT="I need a motif for an AI image generation task. The image will be displayed at the top of a newly started terminal. Please provide $NUMBER_OF_SUGGESTIONS creative and unique motifs which can be used to generate interesting images in an array. Express the motifs in at most five words."
PROMPT_GENERATION_SLOGAN_PROMPT="Please suggest $NUMBER_OF_SUGGESTIONS creative and unique hacker or programmer or sci-fi slogans. The text will be displayed at the top of a newly started terminal. Express the slogans in at most five words."
PROMPT_GENERATION_STYLE_PROMPT="Please suggest $NUMBER_OF_SUGGESTIONS unique art or fashion styles. Be creative. Express the styles in one word each."

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
  # Check that magick is installed
  local magick_command=magick
  if ! command -v magick &> /dev/null; then
    magick_command=convert
    if ! command -v convert &> /dev/null; then
      echo "Neither magick nor convert is installed. Please install ImageMagick."
      return 1
    fi
  fi

  # Check that jq is installed
  if ! command -v jq &> /dev/null; then
    echo "jq is not installed, please install it."
    return 1
  fi

  cd /tmp || { echo "Hello World!"; return 0; }

  local text
  # shellcheck disable=SC2034
  text=$(get_text "$PROMPT_GENERATION_SLOGAN_PROMPT")

  local design
  # shellcheck disable=SC2034
  design=$(get_text "$PROMPT_GENERATION_IMAGE_PROMPT")

  local style
  # shellcheck disable=SC2034
  style=$(get_text "$PROMPT_GENERATION_STYLE_PROMPT")

  # shellcheck disable=SC2034
  local common_text="on a black background in landscape orientation."

  local index=$((RANDOM % ${#PROMPT_TEMPLATES[@]}))
  local prompt
  prompt=$(eval echo "${PROMPT_TEMPLATES[$index]}")

  log "Generated prompt: $prompt"

  local image_url
  image_url=$(get_image_url "$prompt")

  # If we hit the rate limit, pick a random existing image
  if [[ -z "$image_url" || "$image_url" == "null" ]]; then
    log "Image URL is empty or null."
    link_random_existing_image
  fi

  # Download the image
  local prompt_as_filename
  prompt_as_filename=$(echo "$prompt" | tr -d '[:punct:]' | tr ' ' '_')
  local image_name
  image_name=design_"$prompt_as_filename".png
  curl -s -o "$image_name" "$image_url"
  # Check that the image was downloaded and is a valid image
  if ! "$magick_command" identify "$image_name" &> /dev/null; then
    log "Invalid image downloaded from: $image_url"
    link_random_existing_image
  else
    mkdir -p "$IMAGE_FOLDER"
    "$magick_command" "$image_name" -fuzz 10% -trim +repage "$IMAGE_FOLDER/$image_name"
    ln -sf "$IMAGE_FOLDER/$image_name" "$IMAGE_FOLDER/latest.png"
  fi
}

display_banner_image() {
  local height=$DEFAULT_HEIGHT
  local width=$COLUMNS
  ## if no COLUMNS is set, default to 80
  if [[ -z "$width" ]]; then
    width=$DEFAULT_WIDTH
  fi

  # Check if we are running in WEZTERM
  if [[ -n "$WEZTERM_EXECUTABLE" ]]; then
    # We are running in WEZTERM, use its image display capabilities
    wezterm imgcat --height "$height" "$IMAGE_FOLDER/latest.png"
  else
    # Check that tiv is installed
    if ! command -v tiv &> /dev/null; then
      echo "tiv is not installed. Install it from https://github.com/stefanhaustein/TerminalImageViewer?tab=readme-ov-file"
      return 1
    fi
    tiv -w "$width" -h "$height" "$IMAGE_FOLDER/latest.png"
  fi
}

if [[ "$COMMAND" == "generate" ]]; then
  set +m # Disable job control, so that the generate command does not produce job control messages.
  generate_banner_image &
elif [[ "$COMMAND" == "display" ]]; then
  display_banner_image
else
  echo "Usage: $0 generate|display"
  exit 1
fi
