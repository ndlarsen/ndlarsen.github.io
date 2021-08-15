---
layout: post
title: "Building a simple web application gateway, part 1"
alttitle: "I bought a NAS - A journey into self-hosting begins"
subtitle: "First steps"
date: 2021-08-14 10:18:33 +0200
categories: [linux,nginx,SSL,docker,self-host,"reverse proxy",nginx,"web application gateway"]
---

## Preface
---
Recently, I bought a NAS device, more specifically, the
[Asustor Lockerstor 4 (AS6604T)](https://www.asustor.com/product?p_id=69). I did this as, in addition to just reaching
a point where I needed more available storage, I also wanted to self-host services such as
[Nextcloud](https://nextcloud.com/) and
[Vaultwarden](https://github.com/dani-garcia/vaultwarden)(Bitwarden compatible backend) on my LAN behind a
[VPN](https://en.wikipedia.org/wiki/Virtual_private_network). As all of these services should be available, both on LAN
and VPN, under a domain from a dynamic DNS provider as either `mydomain.ddnsprovider.tld/service` or
`service.mydomain.ddnsprovider.tld` I eventually found myself in need of a
[web application gateway](https://en.wikipedia.org/wiki/Application-level_gateway).

While it is my impression (from what I have read and heard, I have no personal experience on this matter) that the
software platform of the Lockerstor 4, as well as the remaining Asustor NAS products, are less polished and a little
behind that of e.g. QNAP and Synology, the hardware platform is solid. This was the most important thing to me as I
just wanted a decent hardware platform onto which I could install an arbitrary Linux distribution when the product
eventually and inevitably reaches end-of-life and in the meantime could deploy docker containers to. Even though the
Lockerstor 4 does check both those boxes, I do have (quite) a few niggles and moans about the design decisions made by
Asustor going into the software platform. I guess there is a certain degree of configurability and control, that I
prefer, which is difficult to maintain while also ensuring some degree of simplicity and usability and I found myself
setting up several init scripts to circumvent some of the platform's limitations - but I digress...

Since a [Vaultwarden server docker image](https://hub.docker.com/r/vaultwarden/server) was already available I figured
that setting up a Vaultwarden instance would be simple and to some degree it was but during testing the setup I hit a
snag, though. Wanting to access the Vaultwarden instance vis HTTPS, I used a
[self-signed](https://en.wikipedia.org/wiki/Self-signed_certificate) SSL certificate. Accessing the instance via browser
plugins while using the self-signed certificate was no issue but the Android app refused to accept it even though I
manually added it to trusted certificates. A properly signed certificate was needed then and luckily, the process of
acquiring one such has become far easier (and cheaper) that is used to be, thanks to
[Let's Encrypt](https://letsencrypt.org/) and others.

I figured the solution would be to use Let's Encrypt as the source for certificates and as I had to acquire a proper
certificate anyway, I though I might as well use this for the remaining services, such as Nextcloud, that I wanted to
host. Thinking this would be fairly simple to do, I began...

## A few roadbumps
---

### Issue A

#### The problem
So, the certificates generated via Let's Encrypt are short-lived, which means they expire after 90 days unless they are
renewed. This I already knew and it is in itself not a massive problem but it does require something to handle the
renewal automatically. I initially though I would use ADM's Certificate Manager for this (ADM being the Asustor software
platform on the NAS) but, at the time of writing, ADM's Certificate Manager only supports certificate renewal via
[domain validation](https://en.wikipedia.org/wiki/Domain-validated_certificate) and
[HTTP-01 challenge](https://letsencrypt.org/docs/challenge-types/#http-01-challenge). Now, I am okay with using domain
validation but a http-01 challenge requires ports 80 and 443 to be exposed to the internet and I did __not__ want that.

#### A solution to A
The [ACME](https://en.wikipedia.org/wiki/Automated_Certificate_Management_Environment) standard defines alternative
challenge types, such as [dns-01](https://letsencrypt.org/docs/challenge-types/#dns-01-challenge). This, in short,
allows one to confirm domain ownership by updating a related DNS TXT record with a value provided by the certificate
issuer after a certificate related request. This seemed like a safer solution to me. However, as ADM's Certificate
Manger did not support this (I have made a feature request to Asustor about it) I needed to brew my own solution and I
also needed to register a domain at a provider who exposed an API capable of updating TXT records. Now, as my ISP is
providing me with a dynamic IP address, I already needed a dynamic DNS for easier access. So a solution to this could be
composed of the following tasks:
* register a domain at a dynamic DNS provider exposing an API to update both A and TXT records
* automate A record renewal
* automate certificate renewal

### Issue B

#### The problem
All the services I want to self-host on the LAN can load and serve the certificate individually. However, when the
certificate changes, the individual service must reload the certificate. For some services this means a complete restart
and others just a reload of the required resources. There are many ways of accomplishing this involving various degrees
of direct/indirect and synchronous/asynchronous communication.

1. direct restart via the docker socket on the host from certificate manager
2. direct restart via HTTP/socket based remote procedure invocation from certificate manager to service
3. indirect restart via direct message based communication
4. indirect restart via publish-subscribe implementation
5. indirect restart via intermediate service manager service

While all of these proposed solutions certainly are possible (and would be fun to implement), they generally introduce
complexity to a setup to a degree which I, in this case, think far outweighs their individual benefits. I think none of
them are appropriate due to the latter in combination with following:

1. allowing a containerized process to manipulate processes on the host system appears to be an anti-pattern, a security
   risk and a catastrophe waiting to happen
2. requires functionality added to both the certificate manager as well as each affected service, also increases
   coupling between the certificate manager and each individual affected service
3. while causing a lower degree of coupling between the certificate manager and the remaining setup, it requires
   functionality to be added to both the certificate manager as well as each affected service. It also requires addition
   of some sort of message channel functionality, either internally or externally
4. while causing a lower degree of coupling between the certificate manager and the remaining setup, it requires
   functionality to be added to both the certificate manager as well as each affected service. It also requires addition
   of some sort of message broker functionality, either internally or externally
5. a service to manage other services would inevitably be somewhat complex, also, t would duplicate functionality
   already available in e.g. systemd, docker, s6 and various other init systems. However, using a preexisting init
   system does not fully remove the coupling from the certificate manager to the remaining system as it would still need
   to be aware of a series of services which would require manipulation after certificate renewal.

Since is does not immediately appear possible to avoid the need to manipulate services after certificate renewal, one
goal should be to reduce the number of services affected as much as possible. While the individual services are serving
the SSL certificate themselves, this is not possible, so the question must be whether or not the SSL certificate can be
served from elsewhere.

#### A solution to B
After digging around a while and talking to people far smarter than me, it appears that a solution could be a
[reverse proxy](https://www.google.com/url?sa=t&rct=j&q=&esrc=s&source=web&cd=&ved=2ahUKEwiluvSI17DyAhXm8rsIHWoZCqAQFnoECAIQAQ&url=https%3A%2F%2Fen.wikipedia.org%2Fwiki%2FReverse_proxy&usg=AOvVaw2MMiofgTfxGMTpQjv60S9E).
Attempting to put this in as few words as possible, a reverse proxy is an intermediate service which when asked for
resources by a client will fetch the resources requested from an alternative backend and return them to the requesting
client. There are many different implementations, [nginx](https://www.nginx.com/) being a widely used one. As the nginx
instance will be receiving the requests and not our backend services, Vaultwarden, nextcloud et el., nginx can serve the
certificate as well, thus changing the need for restarting several backend services to just one - the nginx instance. So
a solution to this could be composed of the following tasks:
* configure a reverse proxy via nginx to handle all requests to the backend services
* have nginx serve the certificate
* ensure reload of nginx after certificate renewal
* ensure domain name resolution on the LA/VPN for all requests for `*.mydomain.ddnsprovider.tld` pointing towards the
  reverse proxy

## What Web Application Gateway?
---
In summary, I need one or more applications capable of fulfilling following requirements:

* automate A record renewal
* automate certificate renewal
* reload nginx after certificate renewal
* reverse proxying
* DNS functionality

I will containerize this via docker and even though there seems to be a widespread adherence to the concept of
_one process per container_, I intend to divide the requirements based on how they conceptually align on the
application level, that is, I will lump the together concepts that I think belongs together into the following
containers/applications.

* dynamic DNS renewal: this functionality is fairly isolated and can run in isolation, in fact, I want this running
  independently of every thing else as I want to reduce risks of downtime
* LAN DNS: as with the dynamic DNS renewal, this will be its own application for the same reasons
* web application gateway: based on the thoughts mentioned under Issue B above, this will a combined application
  including both the certificate renewal and reverse proxy for easier reloading thereof

## Postface
---
At this point I think it is worth mentioning that [linuxserver.io](https://www.linuxserver.io/) has released, what
appears to be, an excellent web application gateway called [SWAG](https://docs.linuxserver.io/general/swag). Now, could
I use this instead? Sure. Why am I not, then? Well, because, firstly, it does far more than I need for this and,
secondly, I would not be learning anything. If I had the need to expose my applications to the general internet, I would
definitely use something more secure, more thoroughly tested and better supported than any homebrewed solution. This
solution might just be SWAG.

I plan on writing additional three posts as part of this series. The next related to setting up dynamic DNS renewal, one
on setting up a local DNS and the final part being related to certificate generation/renewal and setting up the reverse
proxy.

Part 2 in the series can be found here: [Building a simple web application gateway, part 2](building-a-simple-web-application-gateway-part-2)

Enjoy.
