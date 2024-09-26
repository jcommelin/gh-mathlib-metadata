#!/usr/bin/env bash

# Change to the directory where the script is located
cd "$(dirname "$0")"

# GitHub repository details
REPO="leanprover-community/mathlib4"
API_URL="https://api.github.com/repos/$REPO/pulls"

# Get the current timestamp and the timestamp from 10 minutes ago
CURRENT_TIME=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
PAST_TIME=$(date -u -d '2 hours ago' +"%Y-%m-%dT%H:%M:%SZ")

# Fetch the list of pull requests
response=$(curl -s "$API_URL?state=all&per_page=100")

# Check if the response is not empty
if [ -z "$response" ]; then
  echo "Failed to fetch PR data : $CURRENT_TIME" >> stats.log
  exit 1
fi

# Parse the JSON response and filter PRs updated in the last 10 minutes
echo "$response" | jq -r --arg PAST_TIME "$PAST_TIME" --arg CURRENT_TIME "$CURRENT_TIME" '
  .[] | select(.updated_at >= $PAST_TIME and .updated_at <= $CURRENT_TIME) |
  "#\(.number) : \(.updated_at)"
' >> stats.log

# echo "$response" > response.json

# # Parse the JSON response and filter PRs updated in the last 10 minutes
# cat response.json | jq -r --arg PAST_TIME "$PAST_TIME" --arg CURRENT_TIME "$CURRENT_TIME" '
#   .[] | select(.updated_at >= $PAST_TIME and .updated_at <= $CURRENT_TIME) |
#   "#\(.number) : \(.updated_at)"
# '

# echo "CURRENT_TIME: $CURRENT_TIME"
# echo "PAST_TIME: $PAST_TIME"
