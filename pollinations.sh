#!/bin/bash

# Note that the Pollinations API does *not* require an account when using the flux model or the turbo model.

get_image_url() {
  local prompt="$1"
  # No account needed for these
  local model=flux
  # local model=turbo
  # Go to https://auth.pollinations.ai to get a token for this one to work. It is super slow though.
  # local model=kontext

  # New models, not tested much
  # local model=nanobanana
  # local model=seedream

  local encoded_prompt
  encoded_prompt=$(echo "$prompt" | jq -sRr @uri)

  local width=2048
  local height=256

  echo "https://image.pollinations.ai/prompt/$encoded_prompt?width=$width&height=$height&private=true&model=$model&token=$POLLINATIONS_API_TOKEN"
}

