#!/usr/bin/env bash

post_base_dir="post"

category=$1
shift
post_name="${*}"

if [[ -z "$post_name" ]]; then
  echo "usage: ./$0 <category> <post post_name>"
  exit 1
fi

post_dir="${post_base_dir}/${category}"

if [[ ! -d "./content/$post_dir" ]]; then
  echo "${post_dir} does not exist, should we create it?"
  exit 1 # TODO implement
fi


hugo new "post/${category}/${post_name}.md"
