---
title: "Using custom hardware in kubernetes"
date: 2021-09-11T08:55:15+02:00
tags: ["homelab", "kubernetes"]
categories: ["homelab"]
draft: false
---

One major difference between running k8s in a corporate setting vs running in a
homelab is the extreme amount of custom hardware you end up wanting to put into
the cluster. But this isn't really how k8s was meant to be used. Any
workload should be able to run anywhere, and be killed at any time and pop back
up again. At least, for the most part. But I wanted to do some machine learning in my cluster using
[Google Coral](https://coral.ai/) TPU. This is a small usb or pci connected
device that's super optimized for running machine learning on edge devices.
It uses very little power and is blazingly fast compared to running the same
workloads on a CPU.

## Node Feature Discovery

The main solution here was to use the
[Node-feature-discovery](https://github.com/kubernetes-sigs/node-feature-discovery)
(NFD)
project, deployed with a
[k8s-at-home](https://artifacthub.io/packages/helm/k8s-at-home/node-feature-discovery)
helm chart. This tool basically let's you define hardware by creating some
filters for it. Let's take a peak at my config.


```yaml
  usb:
    deviceClassWhitelist:
      - "02"
      - "0e"
      - "ef"
      - "fe"
      - "ff"
    deviceLabelFields:
      - "class"
      - "vendor"
      - "device"
  custom:
    - name: "conbee" # Zigbee usb controller
      matchOn:
        - usbId:
            vendor: ["1cf1"]
            device: ["0030"]
    - name: "apc-ups" # Uninterruptible power supply
      matchOn:
        - usbId:
            vendor: ["051d"]
            device: ["0002"]
    - name: "rtl" # RTL2838 radio dongel
      matchOn:
        - usbId:
            vendor: ["0bda"]
            device: ["2838"]
    - name: "intel-gpu" # Intel integrated GPU
      matchOn:
        - pciId:
            class: ["0300"]
            vendor: ["8086"]
    - name: "coral-tpu" # Coral TPU <--- This is the one
      matchOn:
        - pciId:
            class: ["0880"]
            vendor: ["1ac1"]
```

So the whitelist let's me add some standard devices automatically, but the juice
is in the custom section. Here I'm giving the vendor and device identifiers as reported by `lsusb` or
`lspci`, and adding a label that makes sense to me. NFD will then add these labels to nodes which have
the given device available. An example should give a good idea of what this
looks like in real life.

```bash
  kubectl get nodes -o yaml | yq '.items[].metadata.labels'
```

```yaml
  {
    "beta.kubernetes.io/arch": "amd64",
    "beta.kubernetes.io/os": "linux",
    "feature.node.kubernetes.io/custom-apc-ups": "true",
    "feature.node.kubernetes.io/custom-coral-tpu": "true",
    "feature.node.kubernetes.io/custom-intel-gpu": "true",
    "feature.node.kubernetes.io/custom-rdma.available": "true",
    "feature.node.kubernetes.io/custom-rtl": "true",
    "feature.node.kubernetes.io/pci-0300_8086.present": "true",
    "feature.node.kubernetes.io/usb-ff_0bda_2838.present": "true",
    "kubernetes.io/arch": "amd64",
    "kubernetes.io/hostname": "example.local",
    "kubernetes.io/os": "linux"
  }
```

Here we see my custom device labels added to this one node. For the most part my nodes
only have a subset of these but this is my experimentation box so it has
everything.

Now we know which nodes have a certain piece of hardware, the next step is to
instruct k8s to schedule our pods on a node with the Google Coral.

To do this I've added a node-selector definition to my deployment.

```yaml
  nodeSelector:
    feature.node.kubernetes.io/custom-coral-tpu: "true"
```

Now my deployment will be scheduled only on a node which has the Coral
available. Neat!


## Intel GPU Plugin

For some hardware though we need some extra steps to get everything working. My cluster is
mostly made up of machines with the Intel i7 processor which often comes with an
embedded GPU. This is useful for things like transcoding media from security
cameras or for a media server. To take full advantage of these I use the [Intel
GPU device
plugin](https://github.com/intel/intel-device-plugins-for-kubernetes/tree/main/cmd/gpu_plugin).
This is again installed through a
[k8s-at-home](https://artifacthub.io/packages/helm/k8s-at-home/intel-gpu-plugin)
helm chart and deployed with a similar node-selector as the one above.

This solution gives me greater control over the resource allocation as I can
control how many pods can use the same GPU at the time, and even set
requirements on the deployment itself regarding how much GPU power it needs, just like
we can with CPU and Memory.

```yaml
  resources:
    limits:
      gpu.intel.com/i915: 1
      cpu: 200m
      memory: 2000Mi
    requests:
      gpu.intel.com/i915: 1
      cpu: 35m
      memory: 500Mi
```

I spent quite a bit of time wrapping my head around this so hopefully I saved
you some effort! :)

