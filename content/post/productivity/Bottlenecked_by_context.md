---
title: "Bottlenecked by context"
date: 2026-04-01T10:00:00+02:00
tags: ["claude", "productivity", "management", "automation"]
categories: ["productivity"]
draft: false
---

The biggest challenge for me moving into the manager role was the seemingly
ever growing ToDo list and the massive context switches that are required. My gut
reaction to these problems as an engineer was to automate them, but what do you
do when you don't have the time to automate?

## The on-call calculator
In the first week of my current role I got an email asking me for the on-call
compensation calculations.
We have a weekly on-call rotation and there is a formula for calculating
reimbursement based on passive hours, active hours and salary.
There is also some agreement for adding vacation days,
and previously an Excel sheet has been used to calculate this where data is
fetched from various sources.

I started out with Claude Code having it write a script to fetch the on-call schedule from
OpsGenie and the logged hours from Jira. This was enough for me to fill in the
spreadsheet the first month. Before the next month's report I added support for
fetching salaries and generating the full spreadsheet.
Now it is automatic, I just verify it and ship it.

## Building a library and skills
Earlier there was a lot of hype around MCPs (Model Context Protocol), which was
supposed to be the silver bullet for integrating AI models with any system or
tool. However these have proven to be somewhat bloated and noisy, and most tools
still lack them. What I was doing now was taking advantage of existing APIs and
functionality only implementing what I needed.

What I found was that every time I asked Claude to integrate with some tool
to fetch some data, we ended up adding it to a personal library of sorts. It was
written in Python and relied on existing libraries where available, or just plain
APIs in other cases.

Now that I had these scripts available I could wire them up as Claude skills,
short text snippets that tell Claude how to do something (more
[here](https://code.claude.com/docs/en/skills)). For instance, '/briefing'
would fetch notifications from various tools, emails, upcoming calendar events,
who is on call and who is on vacation, print that data in a table and write a
short summary highlighting important findings. Interestingly enough, one of the first
times I used this skill it informed me that the engineer who was on-call the
following week also was on vacation. Nice save.

Another seemingly mundane skill which has been quite valuable fetched the full
org tree from our HR tool.
Every employee, their name, title and who they report to. I added this
because we were doing some org changes at the time and I wanted a way to keep
track of what was happening.
Now I ask Claude for an update and Claude takes the diff between the org tree
from yesterday and today, which generates a changelog of who was promoted, hired, or left. And it's
actually really helpful when working in a global company to keep on top of these
things.

On the topics of skills, you can get some help to write your skills using the
'skill-creator' skill which can be found and installed by issuing '/plugin' in
Claude Code.

## Building context
This use case didn't fully fall into place until we started transitioning to SAFe (Scaled
Agile Framework). Since we are many teams with various processes this was a huge
change for us, and required a lot of coordination, meetings, training and
discussions. I didn't have time to join all the meetings because they sometimes clashed with
existing ones. Luckily they were all recorded with automatic transcription.

I had a Slack plugin to fetch conversations, so I had Claude add a sync
option to sync an entire channel to my newly created SAFe folder on my laptop.
The same was true for Confluence, so we added sync there also so the docs were
in my SAFe folder. Finally came the Outlook365 plugin that synced meeting
transcriptions; for this one I made it so I can add regular expressions like "PI
Planning.*" or "SAFE.*" and it synced the transcripts for the meetings whose
title matched that expression.
In this folder I also added a CLAUDE.md file which tells Claude what this folder
contains, some links to SAFe resources like what it is and how it's designed, and finally
some information about me, my teams and my roles.

So now I could ask Claude questions like:
- What are the next big tasks for me?
- What do I need to prepare for <some ceremony>
- Our Technical Architect wants to know their role in PI Planning

The answers I got weren't just about SAFe in general, they were about how we
are implementing it, about the decisions we have made. And there are direct
links to discussions on slack, or meetings where things were discussed or
decided. Claude doesn't do any thinking for me here, it only keeps the context.

I now have many such context folders and they all sync content, some often some
rarely.

## It's all about the context
For me the above adjustments have fundamentally changed how I work.
As an engineer I automated away most of my daily challenges. Now as a manager I use
Claude to overcome the bottleneck and expand and enrich the context I rely on.
I'm not thinking less, I am thinking more about the things that really matter.
