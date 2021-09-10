---
title: "Who needs a homelab"
date: 2021-08-22T10:13:22+02:00
tags: ["homelab", "kubernetes"]
categories: ["homelab"]
draft: false
---

In my second year at the Norwegian Tech & Natural Science University (NTNU) in
Trondheim I joined DotKom. A subcommittee in the student organization which
maintained the infrastructure and web services. One of the perks was that we
were allowed to place one server in the University server room which had a gigabit
internet line. Pretty amazing speeds in 2008. I was a poor student though,
and didn't have the cash to buy a server, so some of the more experienced DotKom
members took me dumpster diving outside the various technical buildings. We
found a surprising amount of hardware, but the best stuff were usually broken in
some way and the rest was pretty old. Eventually I was able to re-purpose a
Dell tower with a Pentium 4 processor and a staggering 4 GB of RAM.
Four or five HDD were set up in RAID and an unhealthy amount
of torrents were leeched and seeded. I took quite a lot of pride in managing a
bash script which would scrape my favorite trackers, download interesting
content, unpack it and finally alert me that new content had arrived. Due to all
the various formats, trackers and quirks though it very much resembled the [xkcd universal installer
script](https://xkcd.com/1654/)

This server naturally also ran a number of other services like an IRC bouncer
(chat), my personal webpage which never got new content, various selfhosted tooling I
was experimenting with etc. Since I got a static public ip from the University
I would usually ssh
into my server to do any kind of heavy duty school work as my laptop was much weaker.
It was like having a cool big brother that was always there to help. But as
anyone who has hosted anything on the public web knows, eventually you'll learn
how to secure your machine from the constant attempts to attack them.


After finishing university I could finally afford some new hardware and bought a top
spec'ed mac mini with a quad core multithreaded i7 processor and a ReadyNAS Pro
6 with 24 TB of disks. To top it all off I bought an Airport Extreme since I was
already going all in an Apple hardware. Everything was great for a while, until
these Raspberry Pi boards started making an appearance.

A tiny computer the size of a credit card for around $5 was mind blowing to me.
Sure it was pretty weak but when version 2 showed up, I jumped all in and bought
5 of them because I wanted to learn about this fancy Kubernetes thing people
were talking about. I'll spare you the details, but compiling custom binaries
for all the needed components was a perilous adventure. When I finally got it
running kubernetes was using most of the available resources, and I started
longing towards more machine power. It looked amazing though, in a custom house
built of Lego!

<img src="/lego_k8s.png" alt="Lego kubernetes" width="75%"/>

At this point I had transitioned from being a programmer with a fetish for
servers and automation to being a "DevOps engineer" building a delivery platform
of internal tooling.
This really fueled my curiosity for new tools as this space is always
growing and changing. So I did the only reasonable thing, I started buying used
enterprise workstation off of Finn, Norways leading marketplace.

Eventually I ended up with 8 machines running kubernetes, 5 Raspberry Pi boards
running various services, a dedicated firewall running OPNsense and a nice big
28 port switch supporting my Power over Ethernet wifi access points and
security cameras.


<img src="/homelab.png" alt="Homelab Diagram" width="75%"/>

You might notice that my old mac mini and macbook pro are still going strong.
Since I'm realizing that this diagram creates more questions than answers I
thought I'd start a blog series going through some of the things I find most
interesting. I'll update this post with links as they're available.

- Network
  - Separation for untrusted devices while allowing remote access
  - Traffic monitoring, analysis and alerting through Loki
  - Getting metrics from a managed switch into Prometheus
- Kubernetes
  - Persistent storage on bare metal, Longhorn and NFS
  - Oauth, Certificates and loadbalancing in and out of the cluster
  - VPN gateway for pods with sensitive data
  - Utilizing specialized hardware like GPUs or Zigbee dongles in specific pods
- Home automation
  - Automating everything with Home Assistant
  - Making dumb cameras smart with Frigate and Google Coral
  - Radiohacking for to find weather and water data
