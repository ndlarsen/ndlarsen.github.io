---
layout: post
title: "Running an application on boot on a linux based system"
date: 2020-11-01 08:44:13 +0100
categories: [linux,systemd,cron,rc.local,raspberry pi]
---

## Preface
---
Working on a project for a friend, the need to run an application at boot on a linux based (Raspberry Pi) system arose. I will briefly go throgh a few approaches to achieve this and likely share my opinions on them. As such, this post is tangentially related to a previous post, [mounting a nfs based unionfs at boot]({% post_url 2019-09-30-mounting-a-nfs-based-unionfs-at-boot %}), in the sense that this will also mention Systemd.

## Common approaches
---
 While there are many approaches to this, I find that three are more commonly used:
 * rc.local
 * cron
 * systemd

### rc.local
`rc.local` is a remnant from older [init](https://en.wikipedia.org/wiki/Init) style boot systems and as far as I can tell, it's deprected and superseded by systemd on most modern linux systems by now. While recommendation of this approach is widespred on the web, personally I'd refrain from using this approach regardless of what init system I would be using. There are two main reasons for that:

1. adding a job to `rc.local` removes the ability to start/stop/restart the job individually and `rc.local` might contain additional jobs as well. As such we're losing granularity and maintainability at the cost of convenience.
2. regardless of which init system you are using, there is likely a defined and documented approach to adding individual jobs/services which offers the combined benefits of robustness, configurability and maintainability.
In addition to that, while the official Raspberry Pi domumentaion itself still [mentions](https://www.raspberrypi.org/documentation/linux/usage/rc-local.md) this approach it does advice againt using it. I figure it's retained for historical purposes.

### cron
`cron` is a time based job scheduler. In all it's simplicity `cron` it is a deamon which runs job scheduled via `crontab` (cron tables). That being e.g. every other Monday, each hour, on the 5th of the month, at 11.00 each day or at reboot and on and on. I am under the impression that running one time/one-off jobs is possible via cron but I recommend using [at](https://linux.die.net/man/1/at) for that instead.

In order to schedule a job to run at every system boot, run
```
crontab -e
```
 and add 
```bash
@reboot /path/to/script.sh
```
It is as simple as that. In order to disable the scheduled job, you would have to either delete or comment the added line out. Scheduled jobs can be added via package install scripts by placing the job file in `/etc/cron.d/` if need be.

### systemd
`systemd` is the de facto replacement for the old school init systems. Through `systemd` we can define and manage system services individually. As already mentioned I wrote about systemd in the post [mounting a nfs based unionfs at boot]({% post_url 2019-09-30-mounting-a-nfs-based-unionfs-at-boot %}) and as such I will not go into details about it here. In oder to add a `systemd` service, place a file in `/etc/systemd/system/` e.g. called `service-name.service` with the following content:

```systemd
[Unit]
Description=Description of this custom service

[Service]
ExecStart=/path/to/script.sh

[Install]
WantedBy=multi-user.target
```
This is the simple version. Additional options are available. After this you should reload systemd service difinitions and enable the service:
```
systemctrl daemon-reload
```
and to enable the unit at boot
```
systemctl enable service-name.service
```
and to enable the unit right away
```
systemctl start service-name.service
```

## In Summary
---
Not much to say about this really. Pick your tool based on needs and use cases. While there is some initial overhead in terms of setup when using systemd, I personally much prefer this approach as we're geting all the systemd goodness and utilities for free.

Enjoy.
