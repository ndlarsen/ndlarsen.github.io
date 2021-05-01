---
layout: post
title: "Verfying systemd unit files"
date: 2020-11-01 17:21:35 +0100
categories: [linux,systemd,today I learned]
---

## Preface
---
Being able to test/verify a systemd unit file while writing it without having to run the service is handy.

### systemd-analyze
`systemd-analyse` can verify the syntax of a unit file. Given this unit definition (which is incorrect):
```systemd
[Unit]
Description=runs "relays.sh test"

[Service]
ExecStart=/home/pi/client/relays.sh test
Requires=network-online.target
After=network-online.target
Restart=on-failure

[Install]
WantedBy=multi-user.target
```
running
```
systemd-analyze verify path/to/some.service
```
will output
```
/home/pi/client/./relays.service:5: Unknown lvalue 'Requires' in section 'Service', ignoring
/home/pi/client/./relays.service:6: Unknown lvalue 'After' in section 'Service', ignoring
```
which tells us that I messed up the unit definition and where. Correcting the content to
```systemd
[Unit]
Description=runs "relays.sh test"
Requires=network-online.target
After=network-online.target

[Service]
ExecStart=/home/pi/client/relays.sh test
Restart=on-failure

[Install]
WantedBy=multi-user.target
```
and running it again yield no output indicationg that the syntax of the unit file is correct.

Enjoy.
