---
layout: post
title: "Using systemd as an alternative to cron"
date: 2020-11-08 15:32:41 +0100
categories: [linux,systemd,cron,today I leaned]
---

## Preface
---
Having poked at bit at systemd lately, I started wondering if one could use systemd as a cron alternative. As it turns out this is possible and pretty simple.

## Services and timers
---
To achieve a scheduled service via systemd we need a service and a timer. The service part is close to what you would expect from any systemd service definition but needs to be marked as of `oneshot` via the `type` attribute in the `Service` section.
### Service
I figured I would try logging selected information about disk usage to the system logs and created a `disk-usage-logger.service` in `/etc/systemd/system/`.
```
[Unit]
Description=Logging information about disk usage to system logs
Wants=disk-usage-logger.timer

[Service]
Type=oneshot
ExecStart=/bin/bash -c 'df -h | grep -e Filesystem -e /home$ -e \\/$'

[Install]
WantedBy=multi-user.target
```
### Timer
As for the timer I created a `disk-usage-logger.timer` in `/etc/systemd/system/`.
```
[Unit]
Description=Timer for 'disk-usage-logger.service'
Requires=disk-usage-logger.service

[Timer]
Unit=disk-usage-logger.service
OnCalendar=daily

[Install]
WantedBy=multi-user.target
```
The `OnCalendar` attribute defines that the timer will trigger the service at midnight every day. The systemd documentation on [OnCalendar](https://www.freedesktop.org/software/systemd/man/systemd.time.html#) outlines the format there of pretty well and it provides ganularity not unlike cron.
Should one want the ensure the timer is triggered at first possible time in case the system is shut down during the trigger time, one can add `Persistent=true` to the `[Unit]` section. All there is left at this point is to enable/start the timer by running
```
sudo systemctrl enable disk-usage-logger.timer
sudo systemctrl start disk-usage-logger.timer
```

Enjoy.
