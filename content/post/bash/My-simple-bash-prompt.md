---
title: "My Simple Bash Prompt"
date: 2019-12-27T11:14:53+01:00
tags: ["bash"]
categories: ["bash"]
draft: true
---

For the last 6 years or so, my simple bash prompt has grown from a short bash
function to a 1k loc project. This holiday I've spent a lot of time improving
it, and adding support for true colors and themes. But my biggest crux has been
speed, or lack there of.

<a href="https://asciinema.org/a/0efgJrqQJY2vH1XguXjX3xV1c" target="_blank"><img src="https://asciinema.org/a/0efgJrqQJY2vH1XguXjX3xV1c.svg" /></a>

## Bash and clean code
I've always felt that a Bash prompt should be written in Bash. My reasoning has
been that Bash is everywhere, so the prompt should not need anything else. If it
does, it's not as 'available', as Bash. Given this requirement, a trade-off
is forced, because 1000 lines of Bash is not very readable. Every
`variable="$(some_helper_function "$my_var")"` will create a subshell, and they
are expensive. On my Macbook pro a subshell costs about 1 ms, on my raspberry
pi the price is 4 times higher. This is made worse by avoiding repetitive code,
a common best practice, which results in more subshells when using helper
functions instead of just repeating the logic.

Another cost is structuring code in separate files so that logically close
functions live together. This is again a 'clean code' practice that will incur a
cost because now the file needs to sourced every time it's needed.



# Concurrency in Bash
To be able to generate every segment of the
prompt as quickly as possible, concurrency is needed. In bash concurrency is
easy, but not so much if you want to keep the output of the concurrent tasks.

```Bash
  execute_segment_script "$segment" "$direction" "$max_length" > "${tempdir}/${i}" & pids[i]=$!
```

This obscurity is how I start a segment generation, output to a tempfile, and
store the pid in an array.

```Bash
  for i in "${!pids[@]}"; do
    wait "${pids[i]}"
    # Add it to the prompt
  done
```

This way we are more or less only bound by the speed of the slowest segment.
Ideally we would be able to wait on all pids and handle them one by one as they
exit, but I haven't found a way to do that. I've tried using named pipes, and
have each concurrent segment write to it on completion, while a second process reads from the
pipe until all segments are done, but that was actually slower than the current
implementation. [xargs](https://stackoverflow.com/a/28358088/3503302) and
[Parallel](https://www.gnu.org/software/parallel/) could have potentially helped
a bit by implementing a thread pool, but none of them really solves the
optimized waiting and output handling. In addition, Parallel is not available
everywhere.


## Avoiding external commands
Another approach has been to remove the use of external programs in favor of
Bash builtins. This has added a lot of speed in many places except for
complicated search and replace like this sed to remove all color (and
surrounding escape brackets)

```Bash
  strip_escaped_colors() {
    sed -E 's/\\\[\\e\[[0123456789]([0123456789;])+m\\\]//g' <<< "$1"
  }
```
For my entire `$PS1` this takes about 6ms on my Macbook Pro as opposed to 12
seconds using bash parameter expansion.


## Solving the problem of speed
Ultimately my goal is for the prompt to load in less than 50ms, which the
Internet claims is the threshold for what we can perceive as delay. And this
fits pretty well with my own observations as SBP renders at around 40ms on my
Ubuntu machine, and 100ms on my Macbook.

So I've tried all the tricks I can think of, reducing the   
