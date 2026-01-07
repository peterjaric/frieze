#!/bin/bash

# Register an account on https://pollinations.ai/ to get an API key, then see list of models at
# https://enter.pollinations.ai/

get_image_url() {
  local prompt="$1"
  local model=zimage

  local encoded_prompt
  encoded_prompt=$(echo "$prompt" | jq -sRr @uri)

  local width=2048
  local height=256
  local token="${POLLINATIONS_API_TOKEN:-}"

  echo "https://gen.pollinations.ai/image/$encoded_prompt?width=$width&height=$height&model=$model&key=$token"
}

