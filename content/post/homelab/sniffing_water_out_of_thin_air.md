---
title: "Sniffing water out of thin air"
date: 2021-09-10T08:59:30+02:00
tags: ["homelab", "kubernetes", "iot"]
categories: ["homelab"]
draft: false
---

I don't like having to relying on other people's computers, aka the cloud, so when I can I
selfhost the tools and services I need. But sometimes there isn't a service to
selfhost. This was the case with my mysterious smart water meter which is now
enforced by my municipality. After some research I found out that I might be
able to get to my precious water data by using a radio dongle. Luckily I already
had one in my gadget drawer. A RTL2838 usb dongle to be precise:

<img src="/RTL2838.jpeg" alt="RTL2838 usb dongle" width="75%"/>


The whole ecosystem for these devices is huge, and there are so many cool
projects to explore. I got stuck playing with a few projects unrelated to my
water meter for a while, and I especially liked
[rtl_433](https://github.com/merbanan/rtl_433). It uses the radio dongle to
listen on 433.92 MHz (and a few other frequencies) looking for known weather
stations. I actually discovered 3 high end stations around my neighborhood which
gave me real time wind, temperature and humidity. I've already ordered an extra
dongle for this use case since there is already an integration with
Home-Assistant in place.

But finally I remembered what I was doing and found the
[wmbusmeters](https://github.com/weetmuts/wmbusmeters) project, which does
exactly what I want. Decode and analyze the signals from smart water meters, and
actually any device using the [WMBUS standard](https://www.ti.com/tool/WMBUS).

I had to compile it for my raspberry pi, but that was a fairly straight forward
process. After a few minutes I was up and running and receiving data from my,
and a few other, water meters. But the data was unfortunately (or fortunately?)
encrypted. The wmbusmeters project has support for decrypting the data but I
would need the decryption key. Since the water meter was installed by the
municipality I didn't have much hope of getting any further.

I shipped an email
to the guy in charge of the water infrastructure, and to my joy, he was really
interested in my little project. Turns out they will have to learn how to do
this exact same task to read off the water usage for houses around the
municipality (that word is starting to annoy me).
So I got my key and boom! Water data! :D

```json
{
  "media": "cold water",
  "meter": "multical21",
  "name": "My Damn Pipes",
  "id": "123456789",
  "total_m3": 463.286,
  "target_m3": 456.264,
  "max_flow_m3h": 0,
  "flow_temperature_c": 11,
  "external_temperature_c": 18,
  "current_status": "",
  "time_dry": "",
  "time_reversed": "",
  "time_leaking": "",
  "time_bursting": "1-8 hours",
  "timestamp": "2021-09-10T07:15:37Z",
  "device": "rtlwmbus[00000001]",
  "rssi_dbm": 156
}
```

I was pretty stoked about how simple this was, and immediately set out to deploy
this to my Kubernetes cluster, hoping I could push the data to Home-Assistant.
The project has good docker support, but unfortunately no Helm chart, so I added one to
[k8s-at-home](https://github.com/k8s-at-home/charts/tree/master/charts/stable/wmbusmeters),
which is where I get most of my helm charts.

The setup was fairly straight forward and with one extra configuration option I
got all that sweet water data into home-assistant:

```bash
    shell=/usr/bin/mosquitto_pub -h vernemq-0.vernemq-headless.data.svc.cluster.local -p 1883 -i wmbusmeters -t wmbusmeters/"$METER_ID" -m "$METER_JSON"
```

This line is added to `Values.config` in the helm chart and basically tells
wmbusmeters to export the data using mosquitto, which passes it to my vernemq
broker. Home assistant is setup to [autodiscover sensors over
mqtt](https://www.home-assistant.io/docs/mqtt/discovery/) and boom, I can make a
nice little dashboard panel!

<img src="/water_panel.png" alt="My water meter panel" width="75%"/>

This is just showing the current temperature and water usage of the day.
You might have noticed from the json above that the usage is reported as
`total_m3`, so every night at 23:59 I reset a simple variable so I know what the
usage was before the day started. By subtracting that value from the `total_m3`
I get today's usage in cubic meters. Also `1m3 == 1000 Liters`.

So that also gives me a nice overview. I need to cleanup those decimals though.

<img src="/water_detailed.png" alt="Water meter graph" width="75%"/>

One issue I had with wmbusmeters though was pretty high cpu usage. After some
digging through their Github Issues I added another configuration line which
let's me ignore the packet types I'm not interested in and let's me be a little
less precise when decoding packets. That cut the CPU usage in half, which is
nice.

```bash
  rtlwmbus:CMD(rtl_sdr -f 868.95M -s 1600000 - 2>/dev/null | rtl_wmbus -p s -a)
```

I had a lot of fun with this, you should try it too! :D
