#!/usr/bin/env bash
# Commit and push the changes in the current checkout of the mirror branch.
#
# GitHub refuses a push over 2 GB, and the first build is about 4 GB, so new and
# changed network files go up in commits of at most BATCH bytes. Deletions and
# index.json come last, in one commit: the manifest never lists a file that is
# not pushed yet.
#
# Usage: push-in-batches.sh <message>    (run inside the mirror checkout)
set -euo pipefail

message=${1:?usage: push-in-batches.sh <message>}
batch_limit=${BATCH:-1000000000}
batch=()
size=0

flush() {
  if ((${#batch[@]})); then
    git add -- "${batch[@]}"
    git commit --quiet --message "$message: ${#batch[@]} networks"
    git push --quiet origin HEAD:mirror
    batch=()
    size=0
  fi
}

while IFS= read -r -d '' path; do
  [[ -f $path ]] || continue # a deletion; it goes in with the manifest
  bytes=$(wc -c <"$path")
  if ((size + bytes > batch_limit)); then
    flush
  fi
  batch+=("$path")
  size=$((size + bytes))
done < <(git ls-files -z --others --modified --exclude-standard -- '*.net.gz')
flush

git add --all
if ! git diff --cached --quiet; then
  git commit --quiet --message "$message"
  git push --quiet origin HEAD:mirror
fi
