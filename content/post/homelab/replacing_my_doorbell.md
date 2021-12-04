---
title: "Replacing my doorbell with a security camera"
date: 2021-09-17T10:12:01+02:00
tags: ["homelab", "iot", "ai"]
categories: ["homelab"]
draft: false
---

So my door bell ran out of
battery, and I started wondering if I could use my security camera instead. In
retrospect I could have gotten some batteries from the battery drawer, but
where is the fun in that!?

So a while back I bought a bunch of Hikvision and Reolink Power over Ethernet (PoE)
4K security cameras. I like them because they only need one wire and have great
quality builds for the price. I don't trust them at all though, so they are
almost completely sealed of from both my network and the internet using a VLAN.
Only my kubernetes cluster can reach them, and nobody else.

When I initially set these cameras up I looked for a tool to capture and save video.
There were a huge number of options, many free, some with usage restrictions and
even more paid solutions. But what I did notice was that they were all pretty
much doing the same thing. Transcoding using GPU, some type of motion
dectection, and many of them where now starting to do object detection using the
[Google Coral TPU](https://coral.ai/). And a lot of them were really old.
So I started searching Github (sorry
Gitlab) for mentions of "Coral" and "[Onvif](https://www.onvif.org/)" a standard
many security cameras rely on which makes using them with different tooling much
easier. That's when I found
[Frigate](https://github.com/blakeblackshear/frigate).

## Frigate

At the time the project was fairly new, but it had everything I wanted. It could
do GPU offloading for transcoding of video, so less CPU usage. There was super
fast object detection using the Coral, again much less CPU usage. And finally it
had a good Home Assistant integration via MQTT so I could easily set it up in my
existing system and I could use the Home Assistant app to view my cameras. So
both mobile and web access; Score!

Since I had [already setup 4 google
corals](https://blog.brujordet.no/post/homelab/using_custom_hardware_in_kubernetes/)
in my kubernetes cluster, I was ready to start playing with Frigate right away. (You might
have forgotten, but my mission here was to replace my door bell)

The author of Frigate has a [helm
chart](https://github.com/blakeblackshear/blakeshome-charts/) which I use to
deploy and the [documentation](https://blakeblackshear.github.io/frigate/) is
actually really good, so that should cover all your needs. But in summary, you
need to define your cameras and tell Frigate if it should record everything, or
just certain objects. You can also specify a low quality stream for the object
detection, and a full quality stream for the recording.

For my doorbell replacement though, I had to define some zones within the
camera, so that I could be notified if someone is coming to my house.
So let's first look at my Driveway camera:

<img src="/hagen.png" alt="My garden and driveway" width="75%"/>

You might think that it's a bit weirdly angled, but that's intentional. I want to
get both the parking area in front of the house, the beginning of the drive way,
and the entrance to the veranda. You might also notice that there is a huge
problem here with motion detection, the trampoline. So to stop the kids and the
trees from triggering the motion detection I've added a some masks:

<img src="/masks.png" alt="My garden and driveway" width="75%"/>

Now only things that are visible here can trigger the motion detection. I did not
anticipate that my wife would plant more trees along the road, so I might have to deal with that soon.

The final step is to add zones, so Frigate can tell me in what area an object
has been detected.

<img src="/zones.png" alt="My garden and driveway" width="75%"/>

So the bluish zone to the left is "parking", the orange zone on the top is
"road" and finally at the yellow zone at the bottom is "veranda". Now frigate will
send MQTT messages every time it detects movement. It could be only
movement and no objects, or multiple objects all at once. The JSON payload in
the MQTT message will have two objects which are Before and After. So if a
person walks into the "road" zone, I'll get an MQTT message with an event saying
that 'Before' there was nothing anywhere, but 'After' there was a 'Person' in
the zone 'Road'. This makes it very easy to write simple automations in Home
Assistant like so:

```yaml
- id: arrival_notification
  alias: Notify that something has arrived
  description: ''
  trigger:
  - platform: mqtt
    topic: frigate/events
  condition:
  - condition: template
    value_template: '{{ trigger.payload_json["after"]["label"] in ["person","car"]}}'
  - condition: template
    value_template: '{{ "road" in trigger.payload_json["before"]["current_zones"]}}'
  - condition: template
    value_template: '{{ "parking" in trigger.payload_json["after"]["current_zones"]}}'
  action:
  - service: notify.notify
    data_template:
      message: A {{ trigger.payload_json['after']['label'] }} has arrived
      data:
        attachment:
          url: https://hassio.example.com/api/frigate/notifications/{{trigger.payload_json['after']['id']}}/thumbnail.jpg
          content-type: png
          hide-thumbnail: false
  - service: tts.google_translate_say
    data_template:
      entity_id: media_player.livingroom_speaker
      message: A {{trigger.payload_json['after']['label']}} has arrived.
```

So this automation is triggered by an MQTT message on the 'frigate/events'
topic, and checks if a person or a car is detected in the 'After' object. We
also check if the object was first in the 'Road' zone and later in the 'Parking'
zone. Meaning this object is actually coming towards the house. And finally, we
send a notification to my phone, with a thumbnail of the object. I also have a
speaker in the living room announcing these events, because I like robot voices
:D

There's also a reverse automation to alert me when something is leaving,
but that one doesn't really help me with the 'doorbell ran out of battery'
situation.

Frigate uses a pre-trained model for the object detection which works really
well for most things I've tried. It also has a lot of objects I haven't bothered
testing, but I'm still waiting for it to detect motion from
a toaster though. It's probably an ominous sign.

Let's instead finish off by watching an event unfold:

<img src="/frigate.gif" alt="My garden and driveway" width="75%"/>

As I'm walking in the 'Road' zone Frigate quickly identifies me as a person with 77%
accuracy. This event alone does nothing for my automation, but as I pop out behind those trees I'm
again identified now with 84% accuracy as I enter the 'Parking' zone. This
triggers my Home Assistant automation and a notification is sent to my phone:

<img src="/person.jpeg" alt="My person being detected" width="75%"/>

The notification is in Norwegian on the screenshot from my phone, but it says
"A person has arrived".

Frigate has been rock solid for me for almost a year now, and
there are lot's of cool features in the pipeline and on the drawing board. One
thing I'm particularly interested in is license plate detection on cars, so I
can know if it's my wife that have just arrived or if it's the pizza delivery
guy. Both are great, but one has pizza!

Unfortunately that is a risky landscape with regards to privacy so it might
be hard to get right.

If you have a camera lying around I really recommend you give Frigate
a try, as you can even get the object detection without the Coral, at the
cost of higher CPU usage.
