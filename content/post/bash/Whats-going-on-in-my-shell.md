---
title: "What's going on in my shell?"
date: 2019-11-09T15:13:36+01:00
draft: false
---

To help me figure this out, I use a few shell functions. Firstly, I need to know
what configuration file that was used.

```bash
function shell_init_file() { # Returns what would be your initfile
  if [[ $- == *i* ]]; then
    echo ~/.bashrc
  elif [[ -f ~/.bash_profile ]]; then
    echo ~/.bash_profile
  elif [[ -f ~/.bash_login ]]; then
    echo ~/.bash_login
  elif [[ -f ~/.profile ]]; then
    echo ~/.profile
  else
    echo "Could not find any config files.."
    exit 1
  fi
}
```

This function checks if we're in an interactive shell or not, and loads bashrc
if we are. If not it checks for the various login files.

Thats all great, but now we need to figure out what files have been sourced from
that first file.

```bash
function _sourced_files(){ # Helper for sourced_files
  sed -En 's/^[.|source]+ (.*)/\1/p' "$1" | while IFS= read -r f; do
    expanded=$(echo ${f/#\~/$HOME} | envsubst | tr -d '"')
    echo "$expanded"
    _sourced_files "$expanded"
  done
}

function sourced_files() { # Lists files which (s/w)hould have been sourced to this shell
  init_file=$(shell_init_file)
  echo "$init_file"
  _sourced_files "$init_file"
}
```

The function `sourced_files` is just a wrapper that checks the initial config
file, and then calls `_sourced_files` to recursively check what files are then
being sourced.

Now we have some kind of idea about what is being configured in our shell. You
might have noticed hat I add `# some description` after my function definitions?
This is so I can get these two nifty helpers:

```bash
alias halp='echo -e "Sourced files:\n$(sourced_files | sed "s#$HOME/#~/#")\n # \nFunctions:\n$(list_functions)\n # \nAliases:\n\n$(list_aliases)" | column -t -s "#"' # Show all custom aliases and functions
```
This is simply an alias that will list my sourced files, and show all functions,
aliases and their description.

```bash
function _wat() { # Completion for wat
  local cur words
  _get_comp_words_by_ref cur
  words=$(list_aliases; list_functions | cut -d ' ' -f 1)
  COMPREPLY=( $( compgen -W "$words" -- "$cur") )
}

complete -o nospace -F _wat wat

function wat() { # show help and location of a custom function or alias
  local query pp
  query="$1"
  pp="cat"
  if [[ -n "$(type bat 2> /dev/null)" ]]; then
    pp="bat -l bash -p"
  fi

  for file in $(sourced_files); do
    awk '/^function '"$query"'\(\)/,/^}/ { i++; if(i==1){print "# " FILENAME ":" FNR RS $0;} else {print $0;}}' "$file"
    awk '/^function \_'"$query"'\(\)/,/^}/ { i++; if(i==1){print "# " FILENAME ":" FNR RS $0;} else {print $0;}}' "$file"
    awk '/^alias '"$query"'=/,/$/ {print "# " FILENAME ":" FNR RS $0 RS;}' "$file"
  done | $pp
  complete -p "$query" 2> /dev/null
}
```

So after looking at what helpers I have available using `halp` I can use `wat`
to show me exactly where it's defined, what it looks like and how it's
auto completed. A sample output would look like this:

```bash
$> wat list_aliases
# /Users/brujoand/src/brujoand/dotfiles/bash/function.bash:66
function list_aliases() { # List all sourced aliases
  for f in $(sourced_files); do
    sed -n "s/^alias \(.*\)=['|\"].*#\(.*\)$/\1 #\2/p" "$f" | sed "s/list_aliases=.*#/list_aliases #/"
  done | sort
}

$> wat list_functions
# /Users/brujoand/src/brujoand/dotfiles/bash/function.bash:60
function list_functions() { # List all sourced functions
  for f in $(sourced_files); do
    sed -n "s/^function \(.*\)() { \(.*\)$/\1 \2/p" <(cat "$f") | grep -v "^_"
  done | sort
}
```

Oh, and this output is pretty printed using `bat`, it's super nice :)
Unfortunately I haven't found a great way of pretty printing code on this blog though :/

So since I tend to write a bunch of shell helpers this setup let's me know
what's going on, where things are defined and what they do.
