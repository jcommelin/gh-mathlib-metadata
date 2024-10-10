#!/usr/bin/env python3

'''
This script looks at all files in the `data` directory and creates a JSON file,
containing information about all PRs described in that directory. For each PR,
we list
- whether it's in draft stage (as opposed being marked as "ready for review")
- whether mathlib's CI passes on it
- the branch it is based on (usually "master")
'''

import json
import os
from datetime import datetime, timezone
from typing import List


def main():
    output = dict()
    updated = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
    output["timestamp"] = updated
    pr_data = []
    # Read all pr info files in the data directory.
    pr_names : List[str] = sorted(os.listdir("data"))
    for pr_number in pr_names:
        with open(f"data/{pr_number}/pr_info.json", "r") as fi:
            data = json.load(fi)
            inner = data["data"]["repository"]["pullRequest"]
            number = inner["number"]
            base_branch = inner["baseRefName"]
            is_draft = inner["isDraft"]

            CI_passes = False
            # Get information about the latest CI run. We just look at the "summary job".
            CI_runs = inner["statusCheckRollup"]["contexts"]["nodes"]
            for r in CI_runs:
                # Ignore bors runs: these don't have a job name (and are not interesting for us).
                if "context" in r:
                    pass
                elif r["name"] == "Summary":
                    CI_passes = True if r["conclusion"] == "SUCCESS" else False
            d = {
                "number": number,
                "is_draft": is_draft,
                "CI_passes": CI_passes,
                "base_branch" : base_branch
            }
            pr_data.append(d)
    output["pr_statusses"] = pr_data
    with open("processed_data/aggregate_pr_data.json", "w") as f:
        print(json.dumps(output, indent=4), file=f)

main()