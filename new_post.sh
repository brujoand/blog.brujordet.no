#!/usr/bin/env bash

function get_current_categories {
  (cd content/post/ && echo * | tr ' ' '\n')
}

function get_current_tags {
  (cd content/post/ && sed -En 's/.*tags: \[(.*)\]/\1/p' ./*/*.md) | tr -cd '[:alnum:][:space:]' | tr ' ' '\n' | sort -u
}

category=$(get_current_categories | fzf --bind enter:accept-non-empty)
[[ -z "$category" ]] && exit 1
tags_list=("$(get_current_tags | fzf -m --bind enter:accept-non-empty)")
tags=$(printf '"%s", ' "${tags_list[@]}")
[[ "${#tags[@]}" -eq 0 ]] && exit 1

read -r -p "Enter title: " title

[[ -z "$title" ]] && exit 1

timestamp=$(date +"%Y-%m-%dT%H:%M:%S%:z")

post_path="content/post/${category}/${title// /_}.md"

cat <<EOF > "$post_path"
---
title: "${title}"
date: ${timestamp}
tags: [${tags%?}]
categories: ["${category}"]
draft: true
---
EOF

"$EDITOR" "$post_path"
