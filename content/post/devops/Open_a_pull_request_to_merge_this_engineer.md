---
title: "Open a pull request to merge this engineer"
date: 2022-07-02T08:00:55+02:00
tags: ["devops", "hiring", "interview"]
categories: ["devops"]
draft: false
---

### The year of interviews

A few years ago the company I worked for had a period of intense hiring.
Over the course of a year I conducted at least 1-2 interviews pr week, so I
ended up taking an active part in shaping our process.

My interviews were usually focused on technical skills for platform engineers or developers,
and the main topic was often; "How do we know that they can code?"
This was also the part we struggled the most with to get right.


In the beginning we used the classic leet code exercises, which I personally just
don't like. It's easy to study a bunch of them and they are often hard to do
under pressure, which can make you miss out on some good people and get a false
positive for others.

So we introduced a live coding challenge where we asked people to start
coding a battle ship game. The goal was never to complete it but to discuss and
more or less write code together. For me this was a perfect way to demonstrate
technical skills in a non-threatening environment. But a lot of people were put
off by live coding and simply froze or make lot's simple mistakes they would never
make normally.

This caused us to give up on the live coding, and instead give it as a "home
assignment". As a live coding exercise it had been obvious that nobody could
complete the assignment, but now when given as a home assignment people felt the
need to complete it, and spent way too much time on the task. I also never liked
home assignment for this reason, as I feel it's way too much to ask of a
candidate who might have 4 or 5 interviews lined up with various companies to
do home assignments for all of them in addition to their current job. We also
had a couple of candidate show up with code they couldn't explain.

### The 'aha moment'

Then while we were on-boarding a new team member, and we were reviewing a pull
request together I realized something. What we are trying to do is to put the
candidate in a "life like situation" and test their technical abilities. But
that doesn't mean we have to make them write code. While we were reviewing this
pull request I got so much information about how our new team member thinks, how
they communicate about the work of others, how they write comments on ways the
pull request author can improve. And all of this requires the technical skills that we are trying to
assess in the first place.

So a week or so later I got to try my "Live pull request review" in an interview. I pulled
out a medium+ sized pull request which added a new feature to one of our
platform tools and printed it out on paper. After giving an introduction to the tool
and the intention of the pull request I asked the candidate to review the pull
request with me and we took notes of all the feedback we had.

I only got to do 4 or 5 of these interviews before we cut back on hiring, but my
experience with this approach were really good. The candidates were much less
intimidated by this than by live coding and there is no "homework".
I also made it clear that this code is written by a potential future team mate
and that they will receive the feedback we write. To me this part is crucial
because it shows how they communicate to others and give feedback, which is a
key part of learning and spreading knowledge.

The other part of this is that after wrapping up the code review, it's natural
to go into a discussion about what happens next. How should the code be
tested, what options do we have for deployment. Let's say we've deployed this
application and it fails with X, how do we troubleshoot? Since we've already
gotten into a collaborative setting, these types of explorations are natural to
move into and they give so much better understanding of someones skills rather
than having a test where they need to remember the implementation details of
quicksort. And as an interviewer these types of interviews are much more
rewarding and require much less preparation.

There are no silver bullets in hiring as you're trying to get the experience from a month of
working together into an hour, but making the experience as enjoyable as
possible and avoiding both live coding and home work seem like good goals to me.
And the quicker we're able to move away from scripted questions into natural conversation the better.
