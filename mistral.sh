#!/bin/bash

get_text() {
  local prompt="$1"
  # local model="mistral-large-latest"
  local model="ministral-8b-2410"

  local response
  response=$(curl -s --location "https://api.mistral.ai/v1/chat/completions" \
     --header 'Content-Type: application/json' \
     --header 'Accept: application/json' \
     --header "Authorization: Bearer $MISTRAL_API_KEY" \
     --data '{
    "model": "'"$model"'",
    "messages": [
        {
          "role": "user",
          "content": "'"$prompt"'"
        }
      ],
        "response_format": {
        "type": "json_schema",
        "json_schema": {
          "name": "prompt_suggestion",
          "strict": true,
          "schema": {
            "type": "object",
            "properties": {
              "suggestion": {
                "type": "array",
                "description": "Suggested motifs for image generation",
                "items": {
                  "type": "string",
                  "description": "A creative and unique motif for image generation"
                }
              }
            },
            "required": ["suggestion"],
            "additionalProperties": false
          }
        }
      }
    }')

    local content
    content=$(echo "$response" | jq -r '.choices[0].message.content')

    local suggestions
    # Parse the suggestions into a bash array
    mapfile -t suggestions < <(echo "$content" | jq -r '.suggestion[]')


  # print random suggestion
  if [[ ${#suggestions[@]} -gt 0 ]]; then
    local random_index=$((RANDOM % ${#suggestions[@]}))
    echo "${suggestions[$random_index]}"
  else
    echo "No suggestions found in the response."
    echo "$response"
    # exit script
    exit 1
  fi
}
