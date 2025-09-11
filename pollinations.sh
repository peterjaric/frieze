#!/bin/bash

get_image_url() {
  local prompt="$1"
  # local model=flux
  # local model=turbo
  local model=kontext

  local encoded_prompt
  encoded_prompt=$(echo "$prompt" | jq -sRr @uri)

  echo "https://image.pollinations.ai/prompt/$encoded_prompt?width=1024&height=512&private=true&model=$model&token=$POLLINATIONS_API_TOKEN"
}

