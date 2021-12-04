---
title: "Forcing my Reolink cameras to play nice with the other kids"
date: 2021-12-04T09:09:42+01:00
tags: ["homelab", "iot", "ffmpeg", "transcoding"]
categories: ["homelab"]
draft: false
---

So from my [post about replacing my doorbell with a security
camera](https://blog.brujordet.no/post/homelab/replacing_my_doorbell/) you might
have noticed that I have a accumulated quite a few PoE security cameras that I
use with [Frigate](https://github.com/blakeblackshear/frigate) to get object
detection and fancy integrations with
[Home-Assistant](https://www.home-assistant.io/). The part I didn't go into
detail about was the struggle with my latest cameras, the [Reolink
820a](https://reolink.com/product/rlc-820a/].

So on the surface these cameras are great. They look nice, support power over
Ethernet, doesn't rely on a cloud service and are very simple to set up. They
sport 4k resolution and have decent night vision capabilities. The problem comes when
you want to integrate them with any kind of selfhosted NVR software, like
Frigate, since they only support H265 for the high resolution stream. H265 or High
Efficiency Video Coding (HEVC), is the successor to the widely used H264. The
benefits of H265 is that it offers  much better compression, but the problem is
that purchasing a license for H265 is much more expensive so many browser and
other tools don't support it. In addition, the "substream" which is a
common feature among security cameras which is basically a second video stream
that has a lower resolution and framerate to do object and
motion detection on, had a way too low resolution for my usecase. Lower
resolution means you can't easily detect smaller objects, and I need to detect
my tiny cats.

My first approach was to contact support, and to their credit they were
surprisingly helpful. I had noticed that the substream on
the Reolink cameras did use the H264 encoding, so I imagined that it should be
fairly simple to make this change in software for the main stream. As it turned out this wasn't an
uncommon request for the Reolink support team and they had a custom version of the camera
firmware ready for me that I could try. This version of the firmware did change
the main stream to use H264, but unfortunately the image quality was much poorer
and there were weird bugs like that the frame rate of the stream stayed constant
and could not be changed. This didn't solve my problems, and so I decided to
revert back to the stock firmware and manage the stream encoding myself.

Cameras tend to expose an RTSP stream which NVR's like Frigate consume, so I
found this neat project [rtsp-simple-server](https://github.com/aler9/rtsp-simple-server)
which allowed me to redistribute the camera streams. Now the hardest part was
yet to come, as I needed to manually decode H265 and encode H264 in addition to
creating a new substream that matched my requirements. Enter the nightmare that
is trying to learn [FFmpeg](http://www.ffmpeg.org/).


Don't get me wrong, I love FFmpeg, it is incredibly powerful and supports
almost anything you want to do with video. But the learning curve is steep, the
documentation is complete but extremely minimal with details and examples. But
the biggest hurdle is actually all the examples scattered around the internet
which claim to do one thing, but are actually working more by accident than
anything else. This sent me down quite a few rabbit holes and old mailing lists
to figure out what the various flags actually meant. Finally I ended up with
this:

```bash
ffmpeg \
  -use_wallclock_as_timestamps 1 -fflags nobuffer -loglevel warning -hide_banner \
  -rtsp_transport tcp -hwaccel qsv -c:v hevc_qsv \
  -i 'rtsp://admin:password@10.20.1.14:554' \
  -vf 'fps=fps=20,scale_qsv=w=3840:h=2160' -c:v h264_qsv -timestamp now -g 100 \
  -profile main -b:v 6M -c:a copy -f rtsp -rtsp_transport tcp rtsp://0.0.0.0:8554/stua \
  -vf 'fps=fps=5,scale_qsv=w=1280:h=720' -c:v h264_qsv -timestamp now -g 25 \
  -profile main -b:v 1M -an -f rtsp -rtsp_transport tcp rtsp://0.0.0.0:8554/stua_sub
```

Disclaimer; I found it very difficult to fully grasp all of these flags.
Especially since they can change meaning depending on where they are placed
relative to the input and output declarations. So please throw some feedback at
me if you see something that's incorrectly explained.

Input and global arguments:
- `-use_wallclock_as_timestamps 1`: Ignore the timestamps from the source video, as they tend to be wrong.
- `-fflags nobuffer`: Reduce latency by not buffering during the input analysis
- `-loglever warning`: Reduce the noise of the output
- `-hide_banner`: Hide the info banner FFmpeg prints when invoked
- `-rtsp_transport tcp`: Using tcp rather than udp for the input stream
- `hwaccel qsv`: Use Intel QuickSync for hardware acceleration
- `-c:v hevrc_qsv`: Use the hevc decoder from Intel QuickSync to decode the input stream
- `-i 'rtsp://admin:password@10.20.1.14:554'`: Finally we have our input stream from the Reolink camera

Output arguments for the main stream:
- `'fps=fps=20,scale_qsv=w=3840:h=2160'`: Set it to 20fps and 4k resolution at 3840x2160
- `-c:v h264_qsv`: Use the Intel QuickSync encoder to encode the output
- `-timestamp now`: Create new timestamps for the output stream
- `-g 100`: Set the picture group to (fps*5) to force every 5th frame to be an I-frame
- `-profile main`: Use the 'main' quality profile instead of 'high'
- `-b:v 6M`: Set the video bitrate to 6mbps
- `-c:a copy`: Just copy the audio as it is
- `-f rtsp`: Use the rtsp format
- `-rtsp_transport tcp`: Use tcp for the pushing to the rtps stream
- `rtsp://0.0.0.0:8554/stua`: The rtsp-simple-server endpoint where we push the stream

As you can probably tell next comes the output arguments for the substream which
just have a lower resolution and fps, and uses the `-an` flag which ignores the
audio stream as it's not useful in my case.

There are a few things to notice here though. I could have used the open source
`vaapi` library instead of `qsv` but I couldn't get it to work properly as the
stream ended up getting jittery and the performance was slightly worse than with
`qsv`. For an example on how to build a docker container with the required
drivers for qsv take a look at [akashisn/ffmpeg](https://github.com/AkashiSN/ffmpeg-docker)

The other thing is that `scale_qsv` actually supports setting the
framerate, but due to a bug in another library that `qsv` relies on this doesn't
work. I spent a substantial amount of time trying to fix the timestamps both in
the input from the camera but also in the stream I was creating. In it's current
form the transcoder simply ignores the timestamps from the camera and creates
new ones, this turned out to be the most reliable approach. I did have to make
one adjustment to Frigate though which was to remove
`-use_wallclock_as_timestamps 1` from the Frigate `input_args`. For some reason
I've not yet understood, this flag caused the resulting recordings to show
frames out of order.

Now you might ask, with 3 4k cameras how much power are you wasting on this?
Turns out, not so much. I've got two machines which can run the transcoder pod
and a quick peak at `intel_gpu_top` shows that it's not even running at the
maximum frequency which is `1200 MHz`.

<img src="/transcoder_load.png" alt="The load on my transcoder pod" width="75%"/>

And for reference my gpu on the machine that is running the Frigate pod is
barely breaking a sweat, which is expected as it's now shielded from decoding
H265, which it could have done. But that would have made it very cumbersome to
create a decent substream. With the two step approach I can also distribute the
work better on my Kubernetes cluster. A quick note on hardware support though.
I've got two machines with an Intel E-2224G processor, which contains the Intel®
UHD Graphics P630. This GPU can decode and encode H264, but older versions could
not. Something to keep in mind when experimenting with this.

<img src="/frigate_load.png" alt="The load on my frigate pod" width="75%"/>

Btw, the IMC reads and writes kept fluctuating quite a lot, so I'm guessing the
value for reads on the last image is somewhat higher than the actual value.

For the rtsp-simple-server the configuration was very straight forward so I just
needed to set the paths of the mainstream and substreams:

```yaml
    paths:
      stua:
        runOnInit:
          ffmpeg <input_flags> -i 'rtsp://admin:password@10.20.1.14:554' \
            <main_output_flags> rtsp://0.0.0.0:8554/stua \
            <sub_output_flags> rtsp://0.0.0.0:8554/stua_sub
        runOnInitRestart: yes
      stua_sub:
        source: publisher
```

Basically I'm adding a path `stua` which on startup will run the ffmpeg command
we discussed earlier. This command publishes the main stream to the `stua` path,
and the substream to the `stua_sub` path. Right now I'm running all of this in a
single container built like so:

```Dockerfile
FROM aler9/rtsp-simple-server AS rtsp
FROM akashisn/ffmpeg:4.4.1-qsv
COPY --from=rtsp /rtsp-simple-server /
ENTRYPOINT [ "/rtsp-simple-server" ]
```

Eventually though, I'll probably split this into two images, and run one
container for each camera to better be able to share the load on my
Kubernetes cluster.

Now I just add the two streams to Frigate as if it were any other camera
and I can finally have my recordings in a format that any browser can play, and
a substream with high enough resolution to detect my cat's as they wander off
into the sunset. High five :D

Leave a comment:
- [/r/homelab](https://www.reddit.com/r/homelab/comments/r8mhhh/forcing_my_reolink_cameras_to_play_nice_with_the/)
- [/r/homeautomation](https://www.reddit.com/r/homeautomation/comments/r8mj40/forcing_my_reolink_cameras_to_play_nice_with_the/)
