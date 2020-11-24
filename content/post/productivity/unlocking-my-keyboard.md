---
title: "Unlocking My Keyboard"
date: 2020-11-24T21:27:29+01:00
draft: false
tags: ["linux", "vim", "keyboard"]
categories: ["productivity"]
---

tl;dr Remapping caps lock to control and escape on Linux

# The elephant on the keyboard
Nothing good has ever come from pressing the CAPS LOCK key, either accidentally
or intentionally during a heated discussion on IRC. As a long time user of
Macbooks I've used [Karabiner](https://karabiner-elements.pqrs.org/) to improve
the way my keyboard works. My most critical customization is to
let the CAPS LOCK key die. Instead it will send escape if pressed alone, and
control if pressed with any other key. Super nice for vim, the shell and just
about anything. Recently I've decided to come back to the Linux desktop and I
searched far and wide for a replacement for karabiner. Finally I've found the
Interception tools.

# How to get this magic sauce?
So if you head over to [Interception
tools](https://gitlab.com/interception/linux/tools) and install it, and while
you're there you should also grab the [Dual Function
Keys](https://gitlab.com/interception/linux/plugins/dual-function-keys) plugin.

First we create a systemd service in `/etc/systemd/system/udevmon.service`

```bash
[Unit]
Description=udevmon
Wants=systemd-udev-settle.service
After=systemd-udev-settle.service

[Service]
ExecStart=/usr/local/bin/udevmon -c /etc/udevmon.yaml
Nice=-20

[Install]
WantedBy=multi-user.target
```

Note that the udevmon location might vary depending on how you installed it.

Then we should define the referenced `/etc/udevmon.yaml`

```bash
- JOB: "intercept -g `DEVNODE | dual-function-keys -c /etc/builtin-keyboard-modifications.yaml | uinput -d `DEVNODE"
  DEVICE:
    NAME: "Apple Inc. Apple Internal Keyboard / Trackpad"
    EVENTS:
      EV_KEY: [KEY_CAPSLOCK]
```


We're basically saying whenever my apple keyboard is sending events, we hijack
the KEY_CAPSLOCK and do whatever is defined in
`/etc/builtin-keyboard-modifications.yaml`. So you might want to run something
similar to the following to find the name of your keyboard:


```bash
sudo uinput -p -d /dev/input/by-id/X
```

Where 'X' is whatever seems to be your keyboard.
There can be a bunch of different ones laying around so make sure that it has at
least the KEY_CAPSLOCK which we want to remap.

When that's all done we can finally create the actual mapping in
`/etc/builtin-keyboard-modifications.yaml`

```bash
TIMING:
  TAP_MILLISEC: 200
  DOUBLE_TAP_MILLISEC: 150

MAPPINGS:
  - KEY: KEY_CAPSLOCK
    TAP: KEY_ESC
    HOLD: KEY_LEFTCTRL
```


Then all we need is a quick `systemctl enable udevmon.service` and a tiny
`systemctl enable udevmon.service` and bobs your uncle! :D


These tools are crazy powerful and more examples can be found over
[here](https://gitlab.com/interception/linux/plugins/dual-function-keys/-/blob/master/doc/examples.md)
