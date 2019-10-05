---
layout: post
title: "Building a full stack web application, part 2: Storage with MongoDB"
date: 2019-10-05 23:30:00 +0200
categories: [mongodb,docker]
---

## Preface
---
In this part I'll create a MongoDB 4.2.0 container via docker-compose for the storage layer and import some previously generated data.

## Building the container
---
Docker-compose is a utility use to define and run multi.container applications. The compose file is written in [YAML](https://en.wikipedia.org/wiki/YAML). Via the command `docker-compose` one can i.e. build, start or stop the containers defined with the file all at once rather than having to do for each indivudual container.

### docker-compose.yml
Within the project's mongodb folder create a file name `docker-compose.yml`. One could argue that writing a compose file is not needed at this point and one would be right but we're going to in the next part anyway so we might as well do it right away. The contet of the file should what is listed below.
```
version: "3.5"
services:
  fullstack_mongodb:
    image: mongo:4.2.0
    container_name: fullstack_mongodb
    ports:
    - "27017:27017"
    volumes:
    - ./mongodb/data:/data/db
```

#### Explanation
* version: refers to the compose file version. Depending on your version of docker-compose yours might need to be differet.
* services: begins definition of one or more containers
  * fullstack_mongodb: the name of the service being defined
  * image: specifies the image to build the serivice from
  * container_name: the name of the running container
  * ports: mapping bewteen host and container ports (specified on the line below)
  * volumes: mapping between host volumes (or directories) and container volumes (specified on the line below)

### Build, run, stop
The services defined in the compose file can be (re)build with
```
docker-compose build
```
started with
```
docker-compose start
```
and stopped with
```
docker-compose stop
```
A combination of build and start is available as
```
docker-compose up
```
Both `start` and `up` can be run with a `-d` flag to detach and run in the background. Run `man docker-compose` or `docker-compose --help` for more information.

## Importing data
---
As mentioned in the first part I used randomuser to generate some initial data that can be found [here](https://github.com/ndlarsen/fullstack-webapp-guide/blob/master/mongodb/users.json). First we need to copy the file to the container. Replace with the proper path to where you placed the data file
```
docker cp mongodb/users.json fullstack_mongodb:/root/users.json
```
Import the data you just pushed to the container
```
docker exec -it fullstack_mongodb /bin/bash -c 'mongoimport --db fullstack --collection users --type json --file /root/users.json --jsonArray'
```
This shoud output somethis similar to
```
2019-10-05T21:37:53.561+0000	connected to: mongodb://localhost/
2019-10-05T21:37:53.602+0000	10 document(s) imported successfully. 0 document(s) failed to import.
```

The next part of the series will focus on setting up the Play and Scala based REST API.
