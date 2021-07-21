---
layout: post
title: "Disable software updater and notifier on ubutnu 20.04"
date: 2021-05-22 12:54:39 +0200
categories: [linux,ubuntu]
---

## Preface
---
Personnaly, I have gotten a bit annoyed by the unattended upgrades and its automatic check for software updates as well as the periodic prompts.

## Disable unattended upgrades
```console
$ sudo dkpg-reconfigure unattended-upgrades
```
an select `no`. Alternatively, manually edit the `/etc/apt/apt.conf.d/20auto-upgrades` to reflect

```bash
APT::Periodic::Update-Package-Lists "0";
APT::Periodic::Unattended-Upgrade "0";
```
This way the system neither automatically updates the package cache nor automatically installes updates.

## Disable update notifier
```console
$ dconf write /com/ubuntu/update-notifier/no-show-notifications true
```
This should prevent the system from prompting you with notifications about new packages or an outdated package cache.

Note that at the time of writing, 22nd of May 2021, there is still an old bug causing this to work inconsistently.
