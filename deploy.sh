#!/usr/bin/env bash

# If a command fails then the deploy stops
set -e

printf "\033[0;32mDeploying updates to GitHub...\033[0m\n"

# Build the project.
hugo -d public -t m10c

cd public
git add .

# Commit changes.
msg="rebuilding site $(date)"
if [[ -n "$*" ]]; then
  msg="$*"
fi
git commit -m "$msg"

git push origin master
printf "\033[0;32mFinished deploying updates to GitHub...\033[0m\n"
cd ..
