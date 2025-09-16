#!/bin/bash

get_image_url() {
  local prompt="$1"
  # No account needed for these
  local model=flux
  # local model=turbo
  # Go to https://auth.pollinations.ai to get a token for this one to work. It is super slow though.
  # local model=kontext

  local encoded_prompt
  encoded_prompt=$(echo "$prompt" | jq -sRr @uri)

  local width=2048
  local height=256

  echo "https://image.pollinations.ai/prompt/$encoded_prompt?width=$width&height=$height&private=true&model=$model&token=$POLLINATIONS_API_TOKEN"
}

