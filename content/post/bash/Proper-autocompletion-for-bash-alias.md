---
title: "Proper auto-completion for bash aliases"
date: 2021-07-12T09:58:00+02:00
draft: false
tags: ["bash"]
categories: ["bash"]
---

Kevin in The Office once said 'Why waste time say lot word when few word do
trick'. These are words to live by, and this is why I love aliases.
Lately though I've been getting really tired of writing out stuff like:

```bash
  kubectl get pods -n network
```

I was saying too many words.
Step one was to start using contexts with kubectl which let's me omit the `-n
network` part. I used [fzf](https://github.com/junegunn/fzf) to make a handy
little function that would let me switch contexts quickly. But I've got a full
post coming on more of these nice functions so let's save that for later.

But my trouble began when I created the alias for getting pods

```bash
  alias kgp='kubectl get pods'
```

Since I've got auto completion setup for `kubectl` naturally I wanted that for
`kgp` too. But this wasn't trivial. I tried looking at the helper script shipped
with `kubectl` to see if I could tap into that, but it's using functions that
are shipped with bash to extract the word under the cursor for instance. And
since `kgp` isn't something the default completion script would understand this
was a dead end.

A helpful redditor suggested that I look at how sudo does this, since it's able
to autocomplete commands it knows nothing about. Unfortunately sudo just checks
if it should complete any sudo specific things and if not it passes the ball to
the registered completion function for the command, which again doesn't work
because the word we are completing `kgp` is unknown to that function.

After reading through a lot of these magic completion functions being used I
noticed that the truth is written in these variables:

```bash
  COMP_WORDS=([0]="kgp" [1]="")
  COMP_LINE="kgp "
  COMP_CWORD=1
  COMP_POINT=4
```

So the `COMP_WORDS` is just an array of a command and it's arguments.
`COMP_LINE` is simply the full line being completed. `COMP_CWORD` is the index
in the words array of the work currently being completed,
and finally `COMP_POINT` is the index in the string where our cursor is at.

I created a simple function which takes an alias name and returns the exact
command the alias would execute:

```bash
  _expand_alias() {
    local alias_name alias_definition
    alias_name=$1
    [[ -z $alias_name ]] && return 1
    type "$alias_name" &>/dev/null || return 1
    alias_definition=$(alias "$alias_name")
    dequote "${alias_definition//alias ${alias_name}=}"
  }
```
If the alias name is empty or the alias doesn't exist we just return, but if it
does we use the alias command to get it's definition and some variable expansion
along with `dequote` to extract only the command.

Next we need to update the `COMP_WORDS` array with our expanded alias:

```bash
  _update_comp_words() {
    local alias_name alias_value
    alias_name=$1
    alias_value=$2
    [[ -z $alias_name || -z $alias_value ]] && return 1

    local alias_value_array
    read -r -a alias_value_array <<< "$alias_value"
    local comp_words=()

    for word in "${COMP_WORDS[@]}"; do
      if [[ $word == "$alias_name" ]]; then
        comp_words+=("${alias_value_array[@]}")
      else
        comp_words+=("$word")
      fi
    done

    COMP_WORDS=("${comp_words[@]}")
  }
```

This function parses our expanded alias into an array and simply substitutes the
alias with it's expanded form and updates the `COMP_WORDS` array directly. I
would have preferred to use a subshell for this but passing arrays around isn't
very nice, and in this case speed is probably more important than readability.

With these two functions we basically just need to update the rest of the
`COMP_*` variables. This is handled by the full wrapper script which also uses
the two functions above:

```bash
  function _alias_completion_wrapper() {
    local alias_name alias_definition alias_value
    alias_name=${COMP_WORDS[0]}
    alias_value="$(_expand_alias "$alias_name")"
    [[ -z $alias_value ]] && return 1

    _update_comp_words "$alias_name" "$alias_value"
    # Update other COMP variables
    COMP_LINE=${COMP_LINE//${alias_name}/${alias_value}}
    COMP_CWORD=$(( ${#COMP_WORDS[@]} - 1 ))
    COMP_POINT=${#COMP_LINE}

    local previous_word current_word
    current_word=${COMP_WORDS[$COMP_CWORD]}
    if [[ ${#COMP_WORDS[@]} -ge 2 ]]; then
      previous_word=${COMP_WORDS[$(( COMP_CWORD - 1 ))]}
    fi
    local command=${COMP_WORDS[0]}
    comp_definition=$(complete -p "$command")
    comp_function=$(sed -n "s/^complete .* -F \(.*\) ${command}/\1/p" <<< "$comp_definition")

    # Call the original completion script with our expanded alias
    "$comp_function" "${command}" "${current_word}" "${previous_word}"
  }
```

So to set this up all we need is to add the completion hook:

```bash
  alias kgp='kubectl get pods'
  complete -o default -F _alias_completion_wrapper kgp
```

Now when bash wants to provide completion options for our alias it will first
call `_alias_completion_wrapper` which expands the alias and updates the values of
`COMP_WORDS`. Then we update the other `COMP_*` variables with their new values.
Finally we find the completion function for our original command and we then
execute that function passing along the current and previous word to get our
proper auto completion.

