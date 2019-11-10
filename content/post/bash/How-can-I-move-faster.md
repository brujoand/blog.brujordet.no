---
title: "How can I move faster around the shell?"
date: 2019-11-10T13:48:03+01:00
tags: ["bash"]
categories: ["bash"]
draft: false
---

I'm horrible at waiting, so when things are slow or repetitive I tend to
automate them. So when I started working on my first Java project I quickly got
fed up by navigating in and out of these crazy paths. For instance moving from
`src/main/java/com/example/application/package/` to the test path, or back to the
root of the project got boring real quick.

```bash
function backto() { # Go back to folder in path
  local path=${PWD%/*}
  while [[ $path ]]; do
    if [[ "${path##*/}" == "$1" ]]; then
      cd "$path" || return 1
      break
    else
      path=${path%/*}
    fi
  done
}

function _backto() { # completion for backto
  local cur dir all
  _get_comp_words_by_ref cur
  all=$(cut -c 2- <<< "${PWD%/*}" | tr '/' '\n')
  if [[ -z "$cur" ]]; then
    COMPREPLY=( $( compgen -W "$all") )
  else
    COMPREPLY=( $(grep -i "^$cur" <(echo "${all}") | sort -u) )
  fi
}
complete -o nospace -F _backto backto
```

The function `backto` and it's auto completion counterpart, will let me chose
one of the directories in my current path to jump back to. The only caveat is if
there are duplicate names it will jump to the one closest to my current working
directory.

There are also some places I visit more often than others. For those I've
created the `src` function. It let's me set a base directory and then I get
auto completion to cd into that path, no matter what my current
working directory is.

```bash
function src() { # cd into $SRC
  cd "$SRC_DIR/$1" || return 1
}

function _src() { # completion for src
  local cur temp_compreply dir

  _get_comp_words_by_ref cur
  dir=$SRC_DIR/

  if [[ $dir != "${cur:0:${#dir}}" ]]; then
    cur=${dir}${cur}
  fi

  temp_compreply=$(compgen -d "${cur}")
  COMPREPLY=( ${temp_compreply[*]//$dir/} )
}
complete -o nospace -S "/" -F _src src
```
The function itself is quite simple, the main logic is in the auto completion.
However, sometimes I want to jump to somewhere that's not my source dir. For those
cases I use [rupa/z](https://github.com/rupa/z). After installing it, z will
take notes on what directories you visit the most, and allow you to jump
instantly by adding a query such as `z some_directory`.
If there are several matches it will choose based
and frequency and how well the path matches your query. Super useful.


I've also become completely reliant on
[junegunn/fzf](https://github.com/junegunn/fzf). It's a fuzzy
finder which can be used directly on the command line or in your interactive
functions. It takes a list of strings as input, and while you type it filters the results.
During installation it asks you if you would like to use fzf for reverse
history search, and you definitely want to do this. `ctrl-r` has never been this
useful, responsive and easy to use.

One way I've used fzf to improve my helpers is with this alias to check out a
git branch.

```bash
alias gcb='git co "$(git branch -a | sed "s/  //" | grep -v "^*" | fzf)"'
```
<script id="asciicast-42QCJBwOswJn4Anodvc8slZgU" src="https://asciinema.org/a/42QCJBwOswJn4Anodvc8slZgU.js" async></script>

There are also some bash specific settings I like to set, to be able to move
around faster. For instance:

```bash
bind 'set completion-ignore-case on' # Case-insensitive autocompletion
shopt -s nocaseglob # Case-insensitive globbing (used in pathname expansion)
shopt -s cdspell # Autocorrect typos in path names when using `cd`
```

Now I don't need to bother with getting the case right for auto completion, and
I can even be a bit sloppy and cd will adjust my input to match the available
results.

I'm also a big fan of vi, and as such my prompt should reflect that.

```bash
set -o vi
bind 'set show-mode-in-prompt on'
bind 'set vi-cmd-mode-string "\1\e[38;5;4m\e[49m\2 ➜ \1\e[39m\e[00m\2"'
bind 'set vi-ins-mode-string "\1\e[38;5;8m\e[49m\2 ➜ \1\e[39m\e[00m\2"'
```

With these settings I get vi mode enabled, and at the end of my prompt bash will
insert an arrow, which is light green when in normal mode, and gray in insert
mode. But the vi-mode does remove a few useful key bindings I've gotten used to,
so to remedy that, I've got these defined.

```bash
bind -m vi-insert "\C-l":clear-screen
bind -m vi-insert "\C-a":beginning-of-line
bind -m vi-insert "\C-e":end-of-line
bind -m vi-insert "\C-w":delete-word
```

I should probably add that all of the above settings are set in my bash config,
even the bind commands which should probably be set in `~/.inputrc`. One day
I'll read up on the best practices for this, but not today.

Also, a proper keyboard will speed things up :D

<img src="/iris.jpeg" alt="drawing" width="75%"/>

Discussion: [reddit.com/r/bash - post](https://www.reddit.com/r/bash/comments/dug79a/4min_how_can_i_move_faster_around_the_shell/)
