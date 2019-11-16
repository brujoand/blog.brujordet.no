---
title: "Poor man's todo list"
date: 2019-11-16T10:45:44+01:00
categories: ["bash", "productivity"]
tags: ["bash", "gtd", "vim"]
---

I have two modes, completely distracted and dead focused. So naturally I need
some help getting things done. I've tried expensive apps like Omnifocus, cli
apps like Todo.txt or TaskWarrior and everything in between. In the end I
realized that these apps are not for people like me. What works for me is big
heavy tools for long term planning and collaboration like Jira or Trello. For my
day to day stuff, the things I actually check regularly a simple checklist is
more than enough.

## A poor man's todo list

First off I need somewhere to store my todo lists. Dropbox is currently what I
use for this.

```bash
export TDY_PATH="$HOME/Dropbox/tdy"
```

Then we need a function to create and open the file

```bash
function tdy() { # The today todo list
  category=${1:-work}
  tdy_folder="${TDY_PATH}/${category}"
  tdy_current_file="${tdy_folder}/$(date +'%Y/%m/%Y.%m.%d').wiki"
  tdy_current_folder="${tdy_current_file%/*}"
  tdy_previous_file=$(find "$tdy_folder" -type f -exec stat -f "%m %N" {} \; | sort -nr | head -n1 | cut -d ' '  -f 2)

  mkdir -p "${tdy_current_folder}"

  if [[ ! -f "$tdy_current_file" ]]; then
    # Replace the path and '.wiki' with equal signs
    printf '%s\n' "= $(date +'%Y.%m.%d') =" >> "$tdy_current_file"
    if [[ -f "$tdy_previous_file" ]]; then
      grep '\- \[[o ]' "$tdy_previous_file" | sed 's/\[o\]/[ ]/' >> "$tdy_current_file"
    fi
  fi

  if [[ -t 1 ]]; then
    "$EDITOR" "${tdy_current_file}"
  else
    # We're in a pipe, so let's cat this instead
    cat "${tdy_current_file}"
  fi
}
```

Basically we have a function `tdy` that takes an argument, which is the category
for the todo list I want. I generate what should be the file of todays todo,
and create the folder for it if it doesn't exist. I also need to find the
previous todo file since I might have unfinished business there. If todays file
doesn't exist I create it and add the stuff from the last file that was not
completed. This code isn't beautiful, but because there is a bit of manual
lifting I haven't found a good way to clean it up. At the end I check to see if
I'm am being called from a pipe, in which case I just `cat` the list, if not I
open it with whatever application is defined in `$EDITOR`.

I use [Vimwiki](https://vimwiki.github.io) for my lists (and notes), which is
why I have the wiki extension on the list. It let's me make a bullet item into
a todo item by pressing `ctrl-space`, pressing once more completes the task. And
when a task has a subtask which is completed the parent gets an indicator for
this. It looks good and works very well for me.

<img src="/todolist.png" alt="drawing" width="75%"/>

Since I now know where my task are defined, and what format they have, I can
easily search for them, to figure out when they were completed.

```bash
function tdy_done() { # Search for done tasks
  grep -R -i "$1" ${TDY_PATH} | grep '\- \[X\]'
}
```

## Visualizing the todo list

I keep my todo list open in a tmux pane at all times, but I also tend to have a
main monitor, so my laptop screen has nothing on it. So while searching for a
MacOS port of the old [Conky](https://github.com/brndnmtthws/conky) I stumbled
upon [Übersicht](https://github.com/felixhageloh/uebersicht). It's an
application that will let you write HTML/JavaScript to create an overlay on your
desktop background. Mine is [here](https://github.com/brujoand/dotfiles/blob/master/config/ubersicht/todo.widget/index.coffee)
And it looks pretty awesome to me, but I'm no front end wiz.

<img src="/ubersicht.png" alt="drawing" width="75%"/>

## Making the most of the time at hand

I like music, but sometimes its just in the way because what I really want is to
block everything out. My noise canceling headphones do help, but I also like to
spin up some white noise. From the terminal.

```bash
alias noise='play -q -c 2 --null synth brownnoise band -n 2500 4000 tremolo 20 .1 reverb 50'
```

I found this somewhere once, and just adapted it. I don't really understand it
all that well, but I like the sound it makes.

I'm also a big fan of setting timers. For everything. Being deeply focused means that
you'll forget about moving on to other important stuff, or going to lunch.
So I use this simple timer.


```bash
function timer() { # takes number of hours and minutes + message and notifies you
  time_string=$1
  if [[ "$time_string" =~ ^[0-9]+[:][0-9]+$ ]]; then
    hours=${time_string/:*/}
    minutes=${time_string/*:/}
    seconds=$(( ( (hours * 60) + minutes ) * 60 ))
    time_hm="${hours}h:${minutes}m"
  elif [[ "$time_string" =~ ^[0-9]+$ ]]; then
    seconds=$(( time_string * 60 ))
    time_hm="${time_string}m"
  else
    printf '%s' "error: $time_string is not a number" >&2; return 1
  fi

  shift
  message=$*
  if [[ -z "$message" ]]; then
    printf '%s' "error: ne need a message as well" >&2; return 1
  fi

  (nohup terminal-notifier -title "Timer: $message" -message "Waiting for ${time_hm}" > /dev/null &)
  (nohup sleep "$seconds" > /dev/null && terminal-notifier -title "${time_hm} has passed" -sound default -message "$message" &)
}
```

I think half of this is from a StackOverflow response, but it basically takes a
number of minutes, or duration on the form `HH:MM` and sleeps for the
appropriate amount of seconds. When the sleep is over, a notification is
displayed. In this case using `terminal-notifier` which is MacOS specific, but
there are plenty of options for Linux too. The only thing out of the ordinary is
possible the use of `nohup`. It takes the following command and detaches is from
my session so I can even log out and the command will still run until completed.
Oh, and the `>&2` is for writing to `stderr`

I did plan to add a sound to this timer, but I don't seem to need it, so maybe
some other time.

Discussion: [reddit.com/r/bash - post](https://www.reddit.com/r/bash/comments/dx6w5r/5min_blogpost_a_poor_mans_todo_list_and_white/)
