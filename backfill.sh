#!/usr/bin/env bash

# Gather updated PR information for all mathlib PRs which were updated "recently".
# This script returns the exit code
# - 0 if no errors occurred, and data for at least one PR was downloaded,
# - 37 if no errors occurred, but the list of PRs was empty,
# - 1 if the was an error fetching data.

# Surface errors in this script to CI, so they get noticed.
# See e.g. http://redsymbol.net/articles/unofficial-bash-strict-mode/ for explanation.
set -e -u -o pipefail

# Change to the directory where the script is located
cd "$(dirname "$0")"

START=$1
END=$2

CURRENT_TIME=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# GitHub repository details
REPO="leanprover-community/mathlib4"
API_URL="https://api.github.com/repos/$REPO/pulls"

# Fetch the list of pull requests
response=$(curl -s "$API_URL?state=all&per_page=100")

# Check if the response is not empty
if [ -z "$response" ]; then
  echo "Failed to fetch PR data: $CURRENT_TIME"
  exit 1
fi

# Iterate over each number from START to END
for pr in $(seq $START $END); do
  # Check if the directory exists
  if [ -d "data/$pr" ]; then
    echo "[skip] Data exists for #$pr: $CURRENT_TIME"
    continue
  fi

  # Check if the number corresponds to a PR
  if ! gh pr view $pr --repo $REPO > /dev/null 2>&1; then
    echo "[skip] Not a PR #$pr: $CURRENT_TIME"
    continue
  fi

  CURRENT_TIME=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
  echo "Backfilling PR #$pr: $CURRENT_TIME"

  # Create the directory for the PR
  dir="data/$pr"
  mkdir -p "$dir"

  # Run pr_info.sh and save the output
  ./pr_info.sh "$pr" | jq '.' > "$dir/pr_info.json"

  # Run pr_reactions.sh and save the output
  ./pr_reactions.sh "$pr" | jq '.' > "$dir/pr_reactions.json"

  # Save the current timestamp
  echo "$CURRENT_TIME" > "$dir/timestamp.txt"

  # Sleep for 2 minutes to avoid rate limiting
  sleep 2m
done

