---
title: "Debugging Bash like a Sire"
date: 2023-12-23T10:01:00+01:00
tags: ["bash", "productivity", "debugging" ]
categories: ["bash"]
draft: false
---

Many engineers have a strained relationship with Bash. I love it though, but I'm
very aware of it's limitations when it comes to error handling and
data structures (or lack thereof).

As a result of these limitations I often see Bash scripts written very defensively
that define something like:

```bash
set -euxo pipefail
```

These are bash builtin options that do more or less sensible things.
  - e: Exit immediately when a non-zero exit status is encountered
  - u: Undefined variables throws an error and exits the script
  - x: Print every evaluation.
  - o pipefail: Here we make sure that any error in a pipe of commands will fail
  the entire pipe instead just carrying on to the next command in the pipe.

All of these are quite useful, thought I tend to skip the `-u` flag as bash
scripts often interact with global variables that are set outside my scripts.
The `-x` flag is extremely noisy so it's most often used manually when
debugging. And to be honest, I don't really use `-o pipefail` either.
I guess this is a good place for a few words of caution when it comes to this
approach. Feel free to dig into [this reddit
comment](https://www.reddit.com/r/commandline/comments/g1vsxk/comment/fniifmk/),
but to summarize, the behavior of these flags aren't consistent across Bash
versions and they can break your scripts in unexpected ways.

For the current context though the shortcoming with these flags is that they don't necessarily tell
you *where* the problem is, and sometimes not even *what* the problem is.
Because of this I very often recreate the following functions when I interact
with larger code bases:

```bash
function log::info {
  log::_write_log "INFO" "$@"
}

function log::level_is_active {
  local check_level current_level
  check_level=$1

  declare -A log_levels=(
    [DEBUG]=1
    [INFO]=2
    [WARN]=3
    [ERROR]=4
  )

  check_level="${log_levels["$check_level"]}"
  current_level="${log_levels["$LOG_LEVEL"]}"

  (( check_level >= current_level ))
}
```

</br>

First we have a simple function `log::info` as you've probably guessed this is
just a short hand for writing log statements on the `INFO` level. Then we have a
function `log::level_is_active` to check if a given log level is actually active
which is controlled by the global variable `LOG_LEVEL`. We have a very simple
scoring system to determine the value of each level, and the last command simply
checks if the level provided as an argument is the same or higher level than our
defined `LOG_LEVEL`.

```bash
function log::_write_log {
  local timestamp file function_name log_level
  log_level=$1
  shift

  if log::level_is_active "$log_level"; then
    timestamp=$(date +'%y.%m.%d %H:%M:%S')
    file="${BASH_SOURCE[2]##*/}"
    function_name="${FUNCNAME[2]}"
    >&2 printf '%s [%s] [%s - %s]: %s\n' \
      "$log_level" "$timestamp" "$file" "$function_name" "${*}"
    ;;
  fi
}
```
</br>

Then we do the actual logging. We get the log level as the first argument, call
`shift` which basically just shifts the functions arguments to the left. The log level is
now gone from the argument array and we assume that all other arguments are words
to be logged. We check if the log level is active and pull out a neatly
formatted timestamp.

Then there is some more interesting stuff. We fetch the value at position `2` in
the `BASH_SOURCE` array. The `##*/` part is a 'parameter substitution', and
it deletes everything up to (and including) the last `/` character. Basically removing the path
and leaving us with the filename. There are many cool things you can do with
parameter substitution, and you can read more about it over at
[cyberciti.biz](https://www.cyberciti.biz/tips/bash-shell-parameter-substitution-2.html).

The `BASH_SOURCE` variable is a built in variable that contains a list of Bash
source files. They are listed in the order of each function call we've made, so
if we've called multiple functions in the same file, the same file will be
listed several times. The reason we're grabbing the item at index 2 is because the
two last function calls where to `log::info` and `log::_write_log`. They aren't
so interesting to the user. I should probably also mention that I tend to put
these functions in a file called `log.sh` and that's why I name the
functions with the `log::` prefix. It's just a convention and nothing magical. I
also tend to prefix the name of the some functions with `_` to show that it's only
intended to be used internally.

We also pull out the value at index 2 from the `FUNCNAME` variable. Which
works exactly like `BASH_SOURCE` except it's for function names instead of
source files. Then we print a neatly formatted string of the data we've gathered
and prepend `>&2` which redirects the output to stderr instead of stdout.
This is useful to avoid confusing your scripts which might take the log output
as the output of the function doing the logging and try to use that as an
actual value. We don't want that, but rather to show it to the user.

Finally we end up with neatly formatted log lines like so:

```
INFO [23.12.22 18:34:09] [github.sh - github::bootstrap]: Bootstrap has started
WARN [23.12.22 18:34:10] [bazel.sh - bazel::check_buildfarm]: Buildfarm is unavailable
INFO [23.12.22 18:34:11] [bazel.sh - bazel::perform_build]: Starting build execution
INFO [23.12.22 18:35:13] [bazel.sh - bazel::perform_tests]: Starting test execution
INFO [23.12.22 18:37:13] [github.sh - github::perform_release]: Start release execution
INFO [23.12.22 18:37:19] [github.sh - github::perform_release]: Completed release
INFO [23.12.22 18:37:23] [slack.sh - slack::notify]: Informing #release on slack that release 1337 has completed
```
</br>

After having used this approach for a long time and debugging weird and
large bash scripts. I started thinking about these global variables. Could they
do more?

```bash
function log::error {
  log::_write_log "ERROR" "$@"
  local stack_offset=1
  printf '%s:\n' 'Stacktrace:' >&2

  for stack_id in "${!FUNCNAME[@]}"; do
    if [[ "$stack_offset" -le "$stack_id" ]]; then
      local source_file="${BASH_SOURCE[$stack_id]}"
      local function="${FUNCNAME[$stack_id]}"
      local line="${BASH_LINENO[$(( stack_id - 1 ))]}"
      >&2 printf '\t%s:%s:%s\n' "$source_file" "$function" "$line"
    fi
  done
}
```
</br>
For the `log::error` function I've made some adjustments. It prints the log
line, just like `log::info`, but we also loop through every item in
`${!FUNCNAME[@]}` as `stack_id`. The exclamation mark in front of an array
expansion gives us the indexes instead of the value so now we can iterate over
both the `BASH_SOURCE` and `FUNCNAME` arrays as they should have the same length.
We print one line for each `stack_id` and we also grab the value from a new
variable `BASH_LINENO`. The two previous variables are populated at the
execution of the script, with the script filename and default `main` function name, but
`BASH_LINENO` doesn't get it's first value until we've executed a function
within the script. Basically the first values of `BASH_SOURCE` and `FUNCNAME`
are not very useful, so we offset ignore the first value for them, but not for
`BASH_LINENO`.

```bash
ERROR [23.12.22 19:37:19] [utils.sh - utils::require_variable]: Varible GITHUB_TOKEN was required, but is empty
stacktrace:
  ./src/github.sh:main:3
  ./src/github.sh:release:15
  ./src/github.sh:prepare_release:29
  ./src/utils.sh:require_variable:14
```
</br>

An error where we forgot to set a variable is ironic I guess, as it's the `-u`
flag I usually don't set. I instead like to be explicit about which variables
are required. In case we forget to write error log statements we
could also utilize a Bash trap for this with something like:

```bash
trap 'log::error "An error has occurred"' ERR
```
</br>

This way, if the script suddenly exits due to any non-zero result, we still get
an error logged and a stack trace, like a Sire.
