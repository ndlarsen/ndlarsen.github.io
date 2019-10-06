---
layout: post
title: "Building a full stack web application, part 1: Introduction and setup"
date: 2019-10-05 15:17:57 +0200
categories: [angular,play,scala,mongodb,docker]
---

## Preface
---
Never having been exposed to [Angular](https://en.wikipedia.org/wiki/Angular_(web_framework)) I thought I'd build a simple web application as a learning experience. Now, I probably could have chosen an easier path and just use existing [REST](https://en.wikipedia.org/wiki/Representational_state_transfer) [APIs](https://en.wikipedia.org/wiki/Application_programming_interface) to fetch data from but I thought it would be interesting to set up the entire stack myself. Currently I'm planning on writing the frontend in Angular, a backend build in [Play Framework](https://en.wikipedia.org/wiki/Play_Framework) and [Scala](https://en.wikipedia.org/wiki/Scala_(programming_language)) and [MongoDB](https://en.wikipedia.org/wiki/MongoDB) for storage. The REST API and database will be running in [Docker](https://en.wikipedia.org/wiki/Docker_(software)) containers and seeing as it will be a multi-container application I'm expecting to utilise [Docker Compose](https://docs.docker.com/compose/) as well. I'll be using [randomuser](https://randomuser.me) to generate some initial data for the storage. I'm going to start from the buttom and working my way up and I'm currently aiming for a series consisting of four posts in total.

* Part 2, Storage with MongoDB
* Part 3, REST API with Play and Scala
* Part 4, Web application with Angular

## An overview
---
This will be a fairly simple setup as there is just the three components and will overall look like the image below.
![Web application architechture](/assets/images/fullstack-webapp-guide/arch.svg){: .center-image}
One could argue that in a setup as simple as this one might as well leave out the middle part. However, layering an application and separating responsibilities is fundamentally sound, not just in terms of design but also in terms of maintenance, scalability and extendibility. As an added bonus, I get to throw buzzwords such as microservice around as if I know stuff. 

## Preperations and setup
---
### The building blocks
* Docker 18.09.7, build 2d0083d
* Docker-compose 1.17.1
* MongoDB 4.2.0
* Play Framework 2.7.3 with Scala 2.13
* Angular 8

### Docker
If you havn't already, you need to install Docker. For me, running a Debian based distro it is as easy as
```
sudo apt-get install docker.io
```
After this you should consider adding your user the the docker group to avoid having to run all docker commands via `sudo`. From a terminal execute
```
sudo usermod -aG docker ${USER}
```
Verify this succeeded by running `groups` the output should contain *docker* as mine below
```
ndlarsen adm dialout cdrom sudo dip plugdev lpadmin sambashare kvm docker adbusers
```
You might need to reboot in order for the group addition to take effect.

### Docker-compose
If you havn't already, you need to install docker-compose. For me, running a Debian based distro it is as easy as
```
sudo apt-get install docker-compose
```
If this version of docker-compose is causing you problems, install the one directly from Docker as outlines [here](https://docs.docker.com/compose/install/).

### sbt (scala build tool)
In order to build and run Scala applications you need to install sbt. Unless you're installing it via an IDE such as Jetbrains' [IntelliJ IDEA](https://www.jetbrains.com/idea/) you need to add their official package repositories and install it from there.
```
echo "deb https://dl.bintray.com/sbt/debian /" | sudo tee -a /etc/apt/sources.list.d/sbt.list
curl -sL "https://keyserver.ubuntu.com/pks/lookup?op=get&search=0x2EE0EA64E40A89B84B2DF73499E82A75642AC823" | sudo apt-key add
sudo apt-get update
sudo apt-get install sbt
```
Shamelessly copied from the [offcial](https://www.scala-sbt.org/1.x/docs/Installing-sbt-on-Linux.html) documentation. Refer to it if you're not runnning a Debian based distribution.

### Angular
Angular 8 requires nodejs v. 10.9.0 or later. I had to install it as snap in order to get a version recent enough. I chose the v. 10 series as it is an LTS.
```
sudo snap install node --classic --channel=10
```
Install the angular cli
```
npm install -g @angular/cli
```
If you're getting permission related errors refer to [this](https://docs.npmjs.com/resolving-eacces-permissions-errors-when-installing-packages-globally) for a solution.

### Project structure
I created a project structure as outlined below.
```
full-stack-guide/
    ├── mongodb/
    ├── play-api/
    └── angular-app/
```

### Getting data
Randomuser provides a REST API we can use to generate structural indentical but random data. The endpoint `https://randomuser.me/api/?results=10` generates 10. I've already done that and if you want to use the same dataset as I am it is available [here](https://github.com/ndlarsen/fullstack-webapp-guide/blob/master/mongodb/users.json).

### Data structure
Looking at the blob of JSON our data seems to be structured as below
![data structure](/assets/images/fullstack-webapp-guide/data_structure_diagram.svg)
While we probably won't be using all of it later it's a suitable base.

The next part of the series [Building a full stack web application, part 2: Storage with MongoDB]({% post_url 2019-10-06-building-a-full-stack-web-application-part-2-storage-with-mongodb %}) will focus on setting up the storage layer via MongoDB and Docker.
