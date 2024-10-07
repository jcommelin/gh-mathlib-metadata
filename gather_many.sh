#!/usr/bin/env bash

# Gather current PR information for a sequence of mathlib pull requests.

# Surface errors in this script to CI, so they get noticed.
# See e.g. http://redsymbol.net/articles/unofficial-bash-strict-mode/ for explanation.
set -e -u -o pipefail

# The PRs for which to download data.
prs=${1:-""}
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