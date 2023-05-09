---
title: "I can't believe it's not dns"
date: 2023-05-09T08:46:57+02:00
tags: ["devops", "kubernetes", "dns"]
categories: ["devops"]
draft: false
---

## A sudden urge to upgrade
It was a warm spring day, kids were out of the house, I had just finished a
round of Rocket League and I thought; Maybe I should upgrade my kubernetes
cluster?

My homelab cluster is deployed using
[Kubespray](https://github.com/kubernetes-sigs/kubespray) which works by
coordinating a myriad of [Ansible](https://www.ansible.com/) scripts.
It's not the quickest solution, but it's solid and
customizable. These upgrades are usually quite uneventful, but I wanted to make
some larger changes to how my gitops flow works, so I decided to just wipe
everything after backing up all my volumes and start from scratch.


## Well, that's odd
I use [Flux](https://github.com/Fluxcd/flux2) to deploy my workloads into
kubernetes. It's quite frankly dead simple. I add yaml to git, Flux reads yaml
and adds stuff to Kubernetes. But when I bootstrapped Flux into my freshly
installed cluster. Nothing worked. Errors everywhere.

It was quite clear from the logs that Flux couldn't do name resolution. Flux
starts out by fetching all the helm repositories it needs to deploy the helm
charts I've created nice little yaml files for in my git repo. But it couldn't
resolve a single domain name, so now it was stuck.

## So how does DNS in Kubernetes even work?
Well, it depends, but the default behavior when deploying a cluster with Kubespray is to use CoreDNS
and NodeLocalDNS. The LocalDNS is basically a simplified CoreDNS service, that
either responds with cached data or asks CoreDNS. CoreDNS also caches responses,
but can either query an external DNS server or query the Kubernetes API.
This means that there are a couple of CoreDNS pods which serve
as the authoritative DNS for the cluster and has a service that load balances the
traffic among the two pods (10.133.0.3 in my case). LocalDNS is then deployed as
a daemonset with one pod per node and binding on the private ip 169.254.25.10.

So the pods I deploy using Flux don't use CoreDNS directly instead they query
LocalDNS which in turn queries CoreDNS, which again queries either an external
DNS or the Kubernetes API to resolve the request.


## The detour

When I started digging into logs, it became clear that the CoreDNS pods
were doing fine, but the LocalDNS pods were struggling massively.

```
2023/05/05 09:56:06 [INFO] Starting node-cache image: 1.21.1
2023/05/05 09:56:06 [INFO] Using Corefile /etc/coredns/Corefile
2023/05/05 09:56:06 [INFO] Using Pidfile
2023/05/05 09:56:07 [INFO] Skipping kube-dns configmap sync as no directory was specified
2023/05/05 09:56:07 [INFO] Added interface - nodelocaldns
cluster.local.:53 on 169.254.25.10
in-addr.arpa.:53 on 169.254.25.10
ip6.arpa.:53 on 169.254.25.10
.:53 on 169.254.25.10
[INFO] plugin/reload: Running configuration MD5 = 5bc9ac48f7ba58018ec5b8fd787058a9
CoreDNS-1.7.0
linux/amd64, go1.16.8,
[INFO] Added back nodelocaldns rule - {raw PREROUTING [-p tcp -d 169.254.25.10 --dport 53 -j NOTRACK]}
[INFO] Added back nodelocaldns rule - {raw PREROUTING [-p udp -d 169.254.25.10 --dport 53 -j NOTRACK]}
[INFO] Added back nodelocaldns rule - {filter INPUT [-p tcp -d 169.254.25.10 --dport 53 -j ACCEPT]}
[INFO] Added back nodelocaldns rule - {filter INPUT [-p udp -d 169.254.25.10 --dport 53 -j ACCEPT]}
[INFO] Added back nodelocaldns rule - {raw OUTPUT [-p tcp -s 169.254.25.10 --sport 53 -j NOTRACK]}
[INFO] Added back nodelocaldns rule - {raw OUTPUT [-p udp -s 169.254.25.10 --sport 53 -j NOTRACK]}
[INFO] Added back nodelocaldns rule - {filter OUTPUT [-p tcp -s 169.254.25.10 --sport 53 -j ACCEPT]}
[INFO] Added back nodelocaldns rule - {filter OUTPUT [-p udp -s 169.254.25.10 --sport 53 -j ACCEPT]}
[INFO] Added back nodelocaldns rule - {raw OUTPUT [-p tcp -d 169.254.25.10 --dport 53 -j NOTRACK]}
[INFO] Added back nodelocaldns rule - {raw OUTPUT [-p udp -d 169.254.25.10 --dport 53 -j NOTRACK]}
[INFO] Added back nodelocaldns rule - {raw OUTPUT [-p tcp -d 169.254.25.10 --dport 8080 -j NOTRACK]}
[INFO] Added back nodelocaldns rule - {raw OUTPUT [-p tcp -s 169.254.25.10 --sport 8080 -j NOTRACK]}
[ERROR] plugin/errors: 2 netchecker-service.default.svc.cluster.local. AAAA: dial tcp 10.133.0.3:53: i/o timeout
[ERROR] plugin/errors: 2 netchecker-service.default.svc.cluster.local. A: dial tcp 10.133.0.3:53: i/o timeout
[ERROR] plugin/errors: 2 netchecker-service.default.svc.cluster.local. AAAA: dial tcp 10.133.0.3:53: i/o timeout
[ERROR] plugin/errors: 2 netchecker-service.default.svc.cluster.local. A: dial tcp 10.133.0.3:53: i/o timeout
[ERROR] plugin/errors: 2 netchecker-service.default.svc.cluster.local. AAAA: dial tcp 10.133.0.3:53: i/o timeout
[ERROR] plugin/errors: 2 netchecker-service.default.svc.cluster.local. A: dial tcp 10.133.0.3:53: i/o timeout
.... these errors go on forever....
```

There are a couple of things to point out here. Firstly we see a dump of
iptable rules in the beginning. Usually a Container Network Interface (CNI)
handles the internal network and firewall rules for the cluster. But since the
LocalDNS pods
are using host networking instead of the cluster network they are out of scope
and write their own iptable rules. The problem though is that my CNI
[calico](https://www.tigera.io/project-calico/) was overwriting the rules made
by the LocalDNS pods.
Initially I jumped at this as a possible solution, and found a way to instruct
calico to [append the existing rules
instead](https://docs.tigera.io/calico/latest/reference/resources/felixconfig)
which did end up ensuring that the LocalDNS rules were kept around. But as you
might have guessed, this was not the reason for LocalDNS pods timing out
against the CoreDNS service.


## It's all so confusing
The hardest part about this problem was the inconsistency. My initial
deployment with Flux failed hard. So I tried resetting and recreating the
cluster multiple times. And finally I gave up and went to bed. The next morning
though things had happened. Some pods had been created, some of them were
even running but others were crashing. All errors were related to DNS not working.

I tried debugging one of the LocalDNS pods, and sure I could query the CoreDNS
service, almost every time. But sometimes it would time out. The LocalDNS pods
are by default configured to use TCP when querying CoreDNS, while `dig`
which I was using to test prefers UDP. And sure enough, when I added the `+tcp`
flag to my dig commands, forcing it to use TCP, the queries were all failing with a timeout. But why?

Another confusing aspect of this was that the cluster was slowly
moving into a working state with all my deployments becoming healthy, even though
the LocalDNS pods war spewing out errors. After
adding a CoreDNS dashboard I saw that the LocalDNS pods will eventually try
UDP if TCP keeps failing. So now and then they will manage to get a response
from CoreDNS over UDP and cache that response for dear life. I tried to reconfigure the LocalDNS to
use UDP instead, thinking this would surely mitigate the issue. But now all UDP
queries were met with a timeout too. (╯°□°)╯︵ ┻━┻

## Frustration and denial
At this point I was basically questioning my own competence and will to breathe.
I had spent days reading, thinking and creating slack
threads in various public channels. I even created an issue on the CoreDNS Github page
asking for guidance.
The discussions on that issue did steer me in the right direction thought as we
were able to verify that CoreDNS and the LocalDNS pods were configured properly.
This problem had to be related to network and likely related to the CNI, or hardware, or both.

## Slow and steady wins the race
I won't bore you with the details but at this point I had tried and Googled
pretty much everything I could think of. I caught myself mindlessly searching
for "calico kubespray nodelocaldns timeout" and various permutations like some
depressed Zombie whenever I sat down somewhere. But eventually I started digging
more into the network interfaces.
I was looking for hardware problems but found none.
I played with tcpdump to verify that the connections were actually
being made and on a whim did a `netstat -s` to print a summary of statistics for
the network interface grouped by protocols. To my surprise there were a large
amount of checksum errors, and retransmissions. Finally, a proper clue!

A lot of network cards will use have hardware offloading to handle
the checksums which speeds up packet handling, if these checksums are wrong
though, the TCP packet will have to be resent. Armed with a new set of search
terms I found a problem that finally matched mine on the [Calico Github
page](https://github.com/projectcalico/calico/issues/3145) where they suggested
to disable hardware offloading of checksums on the calico interface.

```
sudo ethtool --offload vxlan.calico rx off tx off
```
And voila the DNS issues disappeared completely!! I was ecstatic and the world finally
made sense again. With a new found bounce in my step I
was eager to share the details at work, since I remembered that our Infra team
had struggled with a similar DNS issue in one of our clusters. Luckily it was
the exact same issue, so don't tell my that running a highly available
Kubernetes cluster in your basement is a waste of time!

So this time, it was actually not really DNS.
