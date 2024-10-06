#!/usr/bin/env bash

# Surface errors in this script to CI, so they get noticed.
# See e.g. http://redsymbol.net/articles/unofficial-bash-strict-mode/ for explanation.
set -e -u -o pipefail

TIMEDELTA=$1

# Change to the directory where the script is located
cd "$(dirname "$0")"

# GitHub repository details
REPO="leanprover-community/mathlib4"
API_URL="https://api.github.com/repos/$REPO/pulls"

# Get the current timestamp and the timestamp from TIMEDELTA minutes ago
CURRENT_TIME=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
PAST_TIME=$(date -u -d "$TIMEDELTA minutes ago" +"%Y-%m-%dT%H:%M:%SZ")

# Fetch the list of pull requests
response=$(curl -s "$API_URL?state=all&per_page=100")

# Check if the response is not empty
if [ -z "$response" ]; then
  echo "Failed to fetch PR data : $CURRENT_TIME" >> stats.log
  exit 1
fi

# Parse the JSON response and filter PRs updated in the last TIMEDELTA minutes
prs=$(echo "$response" | jq -r --arg PAST_TIME "$PAST_TIME" --arg CURRENT_TIME "$CURRENT_TIME" '
  .[] | select(.updated_at >= $PAST_TIME and .updated_at <= $CURRENT_TIME) |
  .number
')

echo $prs

# Iterate over each PR number
for pr in $prs; do
  # Create the directory for the PR
  dir="data/$pr"
  mkdir -p "$dir"

  # Run pr_info.sh and save the output
  ./pr_info.sh "$pr" | jq '.' > "$dir/pr_info.json"

  # Run pr_reactions.sh and save the output
  ./pr_reactions.sh "$pr" | jq '.' > "$dir/pr_reactions.json"

  # Save the current timestamp
  echo "$CURRENT_TIME" > "$dir/timestamp.txt"
done

