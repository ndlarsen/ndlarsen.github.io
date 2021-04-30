---
layout: post
title: "User based update-alteratives for terraform"
date: 2021-04-30 18:05:01 +0200
categories: [linux,terraform,today,I,leaned]
---

## Preface
---
It this post I will show you how to utilize `update-alternatives` or the [Debian Alternatives System](https://wiki.debian.org/DebianAlternatives) on a per user level, that is without `sudo` 

## Motive
---
At work we are using [terraform](https://en.wikipedia.org/wiki/Terraform_(software)) as _the_ preferred [IaC](https://en.wikipedia.org/wiki/Infrastructure_as_code) (infrastructure as code) tool. I will not go into details about the benefits af IaC, suffice to say, they are plenty and massive especially when working with a cloud or a cloud-like environment, nor will I go into details about the pros and cons of terraform as an IaC tool.

I will say, though, that one of the things about terraform as a tool, is that it has been evolving and improving quite a lot during the past few years. This in part due to the constant evolution of its supported providers (AWS, Azure et al.) and in part due to the [DSL](https://en.wikipedia.org/wiki/Domain-specific_language) being fairly immature and limited to begin with. As a consequence of this, HashiCorp has been releasing new versions of terraform fairly often and every once in a while changes have been breaking and thus requiring, sometimes substantial, rewrites.

At work we are stiving towards a DevOps-y environment supported by a (micro)service oriented architecture and as such we are supporting and maintaining quite a few services in total, many of which the team I belong to are mostly resposible for. An unfortunate consequence of this has been that not all services has been receiving the same amount of attention and maintenance as one would ideally like (I might just write a post on this later on) and as such we find ourselves using different versions of terraform on a daily basis. Currently I have 0.11 thought 0.15 installed and in use regularly.

Programmers/software engineers are "lazy" in the sense that repeatable tasks are candidates for scripting and/or automation. This means we are having a collection of utility scripts which all expects the terraform binary to actually be named terrraform and not perhaps terraform14.

At work, as at home, I am running a Debian Linux based system, most of us in my subdivision are, at least while at work. Many of us, myself included, have resorted to use the `Debian Alternatives System` which enables us to have multiple versions of an binary or application installed and switch between them fairly easy. If you are reading this, you probably already know of this system. A downside of this, though, is that by default the alternatives system maintains everything in system directories that require root level priviledges to manipulate and thus needs to be run as a priviledged user, e.g. via `sudo`. For system level applications, this can make sense but I do not think does in this case and is unneeded because

1. terraform is not really a system level command with system level impact (at least not on the system on which it is run)
2. my current need for at specific terrraform version, or e.g. Java for that matter, should have no impact on other users, if any, on the same system.

Adding to that, having to type my password every time I need to change terraform version is just excruciating.

Fortunately, there is a way to achieve this via the existing alternatives system but unfortunately not as simple as just passing a `--user` commandline flag to `update-alternatives` or edting a configuration file and be done with it. It takes a little more work to do this and I solved by using other existing commandlie flags to `update-alternatives` and implementing a wrapper script to handle it. Before actually, doing it, I think it is well worth having a look at what the alternatives system is and how it actually works.

## The _Debian Alternatives System_
---
### What it is
As mentioned before, and as you might know, the alternatives systems gives us the ability to have multiple binaries which provides similar funtionality installed at the same time while having a specific one defined as default. What this means is that I can install e.g. both openjdk-8 and openjdk-11 and switch between by them defining the default depending on need. So on  a system I installed both versions with openjdk-8 currently default:

```console
~$ update-alternatives --display java
java - auto mode
  link best version is /usr/lib/jvm/java-11-openjdk-amd64/bin/java
  link currently points to /usr/lib/jvm/java-8-openjdk-amd64/jre/bin/java
  link java is /usr/bin/java
  slave java.1.gz is /usr/share/man/man1/java.1.gz
/usr/lib/jvm/java-11-openjdk-amd64/bin/java - priority 1111
  slave java.1.gz: /usr/lib/jvm/java-11-openjdk-amd64/man/man1/java.1.gz
/usr/lib/jvm/java-8-openjdk-amd64/jre/bin/java - priority 1081
  slave java.1.gz: /usr/lib/jvm/java-8-openjdk-amd64/jre/man/man1/java.1.gz
```

```console
~$ java -version
openjdk version "1.8.0_292"
OpenJDK Runtime Environment (build 1.8.0_292-8u292-b10-0ubuntu1~20.04-b10)
OpenJDK 64-Bit Server VM (build 25.292-b10, mixed mode)
```

After changing default to openjdk-11 by running `sudo update-alternatives --config java`:

 ```console
~$ update-alternatives --display java
java - manunal mode
  link best version is /usr/lib/jvm/java-11-openjdk-amd64/bin/java
  link currently points to /usr/lib/jvm/java-11-openjdk-amd64/bin/java
  link java is /usr/bin/java
  slave java.1.gz is /usr/share/man/man1/java.1.gz
/usr/lib/jvm/java-11-openjdk-amd64/bin/java - priority 1111
  slave java.1.gz: /usr/lib/jvm/java-11-openjdk-amd64/man/man1/java.1.gz
/usr/lib/jvm/java-8-openjdk-amd64/jre/bin/java - priority 1081
  slave java.1.gz: /usr/lib/jvm/java-8-openjdk-amd64/jre/man/man1/java.1.gz
```

```console
~$ java --version
openjdk 11.0.11 2021-04-20
OpenJDK Runtime Environment (build 11.0.11+9-Ubuntu-0ubuntu2.20.04)
OpenJDK 64-Bit Server VM (build 11.0.11+9-Ubuntu-0ubuntu2.20.04, mixed mode, sharing)
```

Notice the difference in on the line that starts with _link currently points to_

### How it works
It is actually quite smart and relatively simple design. For a given binary installed into the alternatives system, the alternatives system maintains three things:
* a file containing meta data about the binary registered with the alternatives system. This file is located within the `admindir` directory which defaults to `/var/lib/dpkg/alternatives/`
* an [symbolic link](https://en.wikipedia.org/wiki/Symbolic_link) within an `altdir` pointing towards the currently configured default alternative binary. This directory defaults to `/etc/alternatives/`
* a main "executable", which is also a symbolic link and pointing towards the default in the `altdir`

So, if I do a `ls -la` on java:

```console
~$ ls -la /usr/bin/java
lrwxrwxrwx 1 root root 22 Apr 30 14:29 /usr/bin/java -> /etc/alternatives/java
```
we can see, `/usr/bin/java` is a symbolic link pointing towards `/etc/alternatives/java` within the default `altdir` and if we do a `ls -la` on `/etc/alternatives/java`:

```console
~$ ls -la /etc/alternatives/java
lrwxrwxrwx 1 root root 43 Apr 30 14:50 /etc/alternatives/java -> /usr/lib/jvm/java-11-openjdk-amd64/bin/java
```

we can see that it points towards `/usr/lib/jvm/java-11-openjdk-amd64/bin/java`

```console
~$ ls -la /usr/lib/jvm/java-11-openjdk-amd64/bin/java
-rwxr-xr-x 1 root root 14560 Apr 21 11:15 /usr/lib/jvm/java-11-openjdk-amd64/bin/java
```
which is an actual binary registered with alternatives system.

Should we `cat` the content of the corresponding meta date file in the `admindir`
```console
~$ cat /var/lib/dpkg/alternatives/java
manual
/usr/bin/java
java.1.gz
/usr/share/man/man1/java.1.gz

/usr/lib/jvm/java-11-openjdk-amd64/bin/java
1111
/usr/lib/jvm/java-11-openjdk-amd64/man/man1/java.1.gz
/usr/lib/jvm/java-8-openjdk-amd64/jre/bin/java
1081
/usr/lib/jvm/java-8-openjdk-amd64/jre/man/man1/java.1.gz
```

we see that it corresponds pretty well to the output of `update-alternatives --display java` for earlier.

To sum it up, the `Debian Alternatives System` works by manipulating symbolic links for a given registered binary and its alternatives while maintaining meta data in a file based "database".

## Utilizing the _Debian Alternatives System_ as a user
### How?
---
According the command `update-alternatives` man page, `altdir` and `admindir` kan be manually defined when called.

Seein as we want to do this for the given user, those directories should probably be located with theat users kome directory. For me, I chose:
* `altdir` -> `~/.local/etc/alternatives`
* `admindir` -> `~/.local/var/lib/alternatives`

Create the needed directories:
```console
mkdir -p ~/.local/etc/alternatives ~/.local/var/lib/alternatives
```

on a more general note, I usually place my own executables/scripts in `~/bin/`. Given we have a `terraform14` and `terraform15` binary in `~/bin/`, we should be able to run the following commands:

```console
update-alternatives --altdir .local/etc/alternatives/ --admindir .local/var/lib/alternatives/ --install ~/bin/terraform terraform ~/bin/terraform15 1
```

```console
~$ update-alternatives --altdir .local/etc/alternatives/ --admindir .local/var/lib/alternatives/ --display terraform 
terraform - auto mode
  link best version is /home/vboxuser/bin/terraform15
  link currently points to /home/vboxuser/bin/terraform15
  link terraform is /home/vboxuser/bin/terraform
/home/vboxuser/bin/terraform15 - priority 1

```

and again for `terraform14`:
```console
update-alternatives --altdir .local/etc/alternatives/ --admindir .local/var/lib/alternatives/ --install ~/bin/terraform terraform ~/bin/terraform15 2
```

```console
~$ update-alternatives --altdir .local/etc/alternatives/ --admindir .local/var/lib/alternatives/ --display terraform 
terraform - auto mode
  link best version is /home/vboxuser/bin/terraform14
  link currently points to /home/vboxuser/bin/terraform14
  link terraform is /home/vboxuser/bin/terraform
/home/vboxuser/bin/terraform14 - priority 2
/home/vboxuser/bin/terraform15 - priority 1
```
### A _small_ isse and a few suboptimal approaches to a "solution"
At this point we can handle the registered binaries as we normally would, albeit we need to supply the `altdir` and `admindir` flags each time which does get just as cumbersome as having to supply sudo and a password, if not worse. I can think of two approaches to solve this but none of them are really great and both causes us to lose the ability to tab-complete and I _really_ like tab-completion. We can either add an alias to our shell
```bash
alias updateAlt='update-alternatives --altdir .local/etc/alternatives/ --admindir .local/var/lib/alternatives/'
```
this would be loaded in whatever file your preferred shell loads when run, for bash I usually use `.profile`. The second approach would be writing a wrapper script and adding a little spice to it while at it. I wrote the one below for work because i am lazy.... You can also download it from here: [here](https://github.com/ndlarsen/ndlarsen.github.io/blob/master/_scripts/terraform_wrapper.sh). I am sure it could easily be modified to be a litte more generic

```bash
#!/bin/bash -e

SCRIPT_NAME=$(basename "$0")

function help {
  echo
  echo -e "a simple 'update-alternatives' wrapper for terraform which allows manipulating terraform binaries for the given user"
  echo
  echo -e "Usage: $SCRIPT_NAME arg1 <arg2>"
  echo -e "  install <terraform_bin_to_add>  <priority> - installs the given alternative with given priority"
  echo -e "  config                                     - for configuring the current default alternative"
  echo -e "  remove <terraform_bin_alternative>         - removes the given alternative"
  echo -e "  display                                    - display current available configurations"
  echo
}

ALT_DIR="$HOME/.local/etc/alternatives"
ADMIN_DIR="$HOME/.local/var/lib/alternatives"
BIN_DIR="$HOME/bin"
TARGET=$BIN_DIR/terraform
NAME=terraform

[ ! -d "$ALT_DIR" ] && mkdir -p "$ALT_DIR"
[ ! -d "$ADMIN_DIR" ] && mkdir -p "$ADMIN_DIR"
[ ! -d "$BIN_DIR" ] && mkdir -p "$BIN_DIR"


function updateAlt {
  update-alternatives --altdir "$ALT_DIR" --admindir "$ADMIN_DIR" "$@"
} 

case "$1" in
  install)
    if [ -z "$2" ]
    then
      echo
      echo "no alternative supplied"
      exit
    fi

    if [ -z "$3" ]
    then
      echo
      echo "no priority for alternative supplied"
      exit
    fi

    BIN_WITH_PATH="$BIN_DIR/$2"
    PRIO="$3"
    updateAlt --install "$TARGET" "$NAME" "$BIN_WITH_PATH" "$PRIO"
    ;;
  config)
    updateAlt --config "$NAME" 
    ;;
  remove)
    if [ -z "$2" ]
    then
      echo
      echo "no path to alternative supplied"
      exit
    fi
    BIN_WITH_PATH="$BIN_DIR/$2"
    updateAlt --remove "$NAME" "$BIN_WITH_PATH"
    ;;
  display)
    updateAlt --display "$NAME"
    ;;
  *)
    help
    ;;
esac
```