#!/bin/bash

get_image_url() {
    local prompt="$1"
    local model='@cf/black-forest-labs/flux-1-schnell'
    # local model='@cf/leonardo/lucid-origin'

    # Create temporary file for the image
    local temp_image_file
    temp_image_file=$(mktemp /tmp/image.XXXXXX.png)
    local random_seed=$((RANDOM % 10000))

    curl -s "https://api.cloudflare.com/client/v4/accounts/$CLOUDFLARE_ACCOUNT_ID/ai/run/$model"  \
    -X POST  \
    -H "Authorization: Bearer $CLOUDFLARE_API_TOKEN"  \
    -d "{ \"prompt\": \"$prompt\", \"seed\": \"$random_seed\" }" | jq .result.image | sed 's/"//g'  | base64 --decode > "$temp_image_file"

    # Extract the image URL from the response
    local image_url
    image_url="file://$temp_image_file"
    echo "$image_url"
}
