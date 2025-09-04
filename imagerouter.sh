#!/bin/bash

get_image_url() {
  local prompt="$1"
  local model='black-forest-labs/FLUX-1-schnell:free'

  local response
  response=$(curl -s 'https://api.imagerouter.io/v1/openai/images/generations' \
    -H "Authorization: Bearer $IMAGEROUTER_KEY" \
    -H 'Content-Type: application/json' \
    --data-raw "{\"prompt\": \"$prompt\", \"model\": \"$model\", \"size\": \"1024x512\"}")

  # Extract the image URL from the response
  local image_url
  image_url=$(echo "$response" | jq -r '.data[0].url')
  echo "$image_url"
}
