---
layout: post
title: "Building a simple web application gateway, part 2"
alttitle: "I bought a NAS - The journey into self-hosting continues"
subtitle: "Renewing dynamic DNS and DNS setup"
date: 2021-08-15 10:31:14 +0200
categories: [linux,docker,self-host,reverse proxy,web application gateway,cron,bash]
---

## Preface
---
As promised in 
[Building a simple web application gateway, part 1 - first steps]({% post_url 2021-08-14-building-a-simple-web-application-gateway-part-1 %})
I would write a post on setting up the following two things:
* a job renewing an entry at a dynamic DNS provider
* a local DNS server

Why would I need this? Well, my ISP (internet service provider) supplies me with a dynamic IP address. What this, in
part, means, is that my external IP address could change from time to time. For most people, this is normally not an
issue, but for me, wanting to reach my NAS from the internet VIA VPN, it could be. Granted, the external IP address very
rarely changes but, nevertheless, I would like this to not interfere with my services and do not want to deal with this
manually. Additionally, I would like to be able to reach each individual service both externally and internally without
having to remember what IP address and port any given service is available on.

## The DNS A record
---
Now, I wont be getting into the all nitty, gritty intricacies of DNS. Suffice to say, for this purpose of this post we
can think of a DNS as a series of tables consisting of records of different types. Thus a request to a DNS results in a
lookup in these tables in an attempt to find a meaningful response. While there are several different type of records,
during this post we are only dealing with records of type `A`, which, in short, is a reference from a domain name, e.g.
`mydomain.tld` to an IP address, e.g. `8.8.8.8` for IPv4 or `0000:0000:0000:0000:0000:ffff:0808:0808` for IPv6.

## Selecting a dynamic DNS provider
---
Seeing as the amount of DDNS (dynamic DNS) providers is substantial, this is not really an easy task. In an attempt to
narrow it down, I defined the following requirements, partially based on the needs described in the introduction post:
[Building a simple web application gateway, part 1 - first steps]({% post_url 2021-08-14-building-a-simple-web-application-gateway-part-1 %}):

* it must provide an API (and not just the web interface) with functionality to
  - update A records
  - update TXT records (for dns-01 domain validation)
* it must provide free domain names (subdomains are fine)
* it must be a free

Evaluating many difference services, I eventually registered a subdomain at [Duck DNS](https://www.duckdns.org/) as the
service fulfilled all desired criteria.

## Dynamic DNS renewal
---
Having picked a DNS provider which seemed suitable I started looking a to options for updating the A record. As most NAS
platforms does provide functionality to accomplish this, it would at this point be reasonable to ask why I do not just
use my new and shiny NAS' software platform, which would be a perfectly reasonable question. Well, the chosen provider
is, at the time of writing, not supported by the NAS and the supported providers does not supply the functionality I
need. Both of which issues I have made feature requests to Asustor about and based on their response the requests have
been added to their backlog.

Meanwhile, I need to find another solution. Based on their [documentation](https://www.duckdns.org/spec.jsp), I figured
a simple shell script and cron for automation would be sufficient. For portability, I opted for `sh` over `bash` and the
result is as follows:

### updateRecord.sh
```sh
#/bin/sh -e

# call the script with either domains as first argument and token as second argument or define the variables
# DOMAIN and TOKEN in the environment (either via sourcing a file or defining while calling)
# examples:
#   ./updateRecord.sh adomain token-value-here
#   DOMAINS=adomain TOKEN=token-value-here ./updateRecord.sh adomain token-value-here
#   . /path/to/env.sh && ./updateRecord.sh adomain token-value-here


withTimestamp() {
  [ ! -z "$1" ] && {
    timestamp=$(date +'%Y-%m-%d %H:%M:%S %Z')
    echo "$timestamp $1"
  }
}

if [ "$#" = 2 ]
then
  DOMAINS="$1"
  TOKEN="$2"
elif [ "$#" != 2 ] && [ "$#" != 0 ]
then
  echo "incorrect amount of arguments supplied"
  exit 1
fi

if [ -z "$DOMAINS" ] || [ -z "$TOKEN" ]
then
  withTimestamp "one or more of the needed arguments is empty"
  exit 1
fi

withTimestamp "attempting to update DNS record at duckdns.org"

RES=$(/usr/bin/curl -s -k "https://www.duckdns.org/update?domains=$DOMAINS&token=$TOKEN&ip=")

if [ "$RES" = "OK" ]
then
  withTimestamp "updated DNS record successfully"
  exit
else
 withTimestamp "something when wrong, failed to update DNS record, received '$RES'"
 exit 1
fi

```

Not really knowing what a sane update interval would be I just picked 45 min and the cron entry could then be:
```sh
45 * * * * /bin/sh -c 'DOMAINS=<YOUR_DOMAINS> TOKEN=<YOUR_TOKEN> /opt/bin/updateRecord.sh'
```
It is worth noting that adding the environment variables like this exposes them as plaintext which is not likely to be 
what you want. While there are other approached to passing environment variables to cron, none of them are really good
but that is a different matter.

### Dockerize it
Not wanting to pollute the underlying NAS environment more than needed, I decided to wrap it all into a docker image. I
realize that some might oppose to this, claiming that running cron in a container is, well, iffy at best and doing so
adds unneeded overhead as shell scripts are sufficiently portable as is. I do not have any strong opinions on the matter
but I do think it is worth being somewhat pragmatic about it and I much prefer passing secrets to a container via
environment variables rather that having them laying around on the NAS's (or a server's) filesystem in plaintext with
the risk of having defined incorrect access permissions for the files.

Cron reads environment variables from `/etc/environment`, while still in plaintext, this is "only" within the container
and the default access permissions should be correct. Of the different approaches I have seen while researching this, I
think this is the least bad one.

#### Dockerfile
Generally, I prefer to base my images in alpine if possible. As alpine currently is one of the smallest images
available, doing so helps keeping the image size down. For this application, a few things must be done in order to build
the image:

1. set the timezone
2. ensure needed tools are available
3. copy the script over
4. define the cron job
5. ensure environment variables are available
6. ensure cron is running 

The result is available below. I am sure there is room for improvement and optimization but for the purpose of this post
and my personal needs, this is "good enough" for now.

```dockerfile
FROM alpine:3.14.0

RUN apk --no-cache add curl tzdata && \
  cp /usr/share/zoneinfo/Europe/Copenhagen /etc/localtime && \
  echo "Europe/Copenhagen" >  /etc/timezone

COPY updateRecord.sh /opt/bin/updateRecord.sh

RUN echo "45 * * * * /bin/sh -c '/opt/bin/updateRecord.sh'" >> /var/spool/cron/crontabs/root

ENTRYPOINT { \
  printenv | grep -e DOMAINS -e TOKEN >> /etc/environment; \
  crond -d 8 -f; \
  }
```

In order for the environment variables being available for the update script, they should be passed as arguments to
`docker run ...` then the line starting with `printenv` under `ENTRYPOINT` takes care of passing them to
`/etc/environment`.

#### Build it
```shell
$ docker build -t duckdns-record-refresh:0.0.1 .
```
#### Run it
```shell
$ docker run -e DOMAINS=<DOMAIN_GOES_HERE> -e TOKEN=<TOKEN_GOES_HERE> -d --restart always --name duckdns-record-refresh duckdns-record-refresh:0.0.1
```

There you have it. Next post in the series will be related to setting up a local DNS.

Enjoy.
