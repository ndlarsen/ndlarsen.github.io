---
layout: post
title: "Building a full stack web application, part 2: Storage with MongoDB"
date: 2019-10-06 08:30:00 +0200
categories: [mongodb,docker]
---

## Preface
---
In this part I'll create a MongoDB 4.2.0 container via docker-compose for the storage layer and import some previously generated data.

## Building the container image
---
Docker-compose is a utility use to define and run multi.container applications. The compose file is written in [YAML](https://en.wikipedia.org/wiki/YAML). Via the command `docker-compose` one can i.e. build, start or stop the containers defined with the file all at once rather than having to do for each indivudual container.

### Dockerfile
Within the project's mongodb folder create a file named `Dockerfile` containing
```
FROM mongo:4.2.0
COPY users.json /root/users.json
```
This will use the mongo 4.2.0 image as base for the image we're building and copy the file containing out seed user data into the container. Docker-compose cannot copy files which is why we're doing it here.

### docker-compose.yml
Within the project's mongodb folder create a file named `docker-compose.yml`. One could argue that writing a compose file is not needed at this point and one would be right but we're going to in the next part anyway so we might as well do it right away. The content of the file should what is listed below.
```
version: "3.5"
services:
  fullstack_mongodb:
    build: mongodb/
    container_name: fullstack_mongodb
    ports:
      - "27017:27017"
```

#### Explanation
* version: refers to the compose file version. Depending on your version of docker-compose yours might need to be differet.
* services: begins definition of one or more containers
  * fullstack_mongodb: the name of the service being defined
  * build: specifies build directory containing the Dockerfile to to build the service from
  * container_name: the name of the running container
  * ports: mapping bewteen host and container ports (specified on the line below)

### Build, run, stop
The services defined in the compose file can be (re)build with
```
$ docker-compose build
```
started with
```
$ docker-compose start
```
and stopped with
```
$ docker-compose stop
```
A combination of build and start is available as
```
$ docker-compose up
```
Both `start` and `up` can be run with a `-d` flag to detach and run in the background. Run `man docker-compose` or `docker-compose --help` for more information.

## Importing data
---
As mentioned in the first part I used randomuser to generate some initial data that can be found [here](https://github.com/ndlarsen/fullstack-webapp-guide/blob/master/mongodb/users.json). We already copied the seed data file to the container in the Dockerfile. We just need to import the seed data into the MongoDB instance inside the container. This executes a mongoimport command inside the container, tellling MongoDB to import the data into a collection named `users` in the database `fullstack` creating both the database and collection is they do not already exist.
```
$ docker exec -it fullstack_mongodb /bin/bash -c 'mongoimport --db fullstack --collection users --type json --file /root/users.json --jsonArray'
```
The command should output something similar to
```
2019-10-05T21:37:53.561+0000	connected to: mongodb://localhost/
2019-10-05T21:37:53.602+0000	100 document(s) imported successfully. 0 document(s) failed to import.
```
At this point you can connect to the container and enter the mongo shell
```
$ docker exec -it fullstack_mongodb /bin/bash -c mongo
```
To get the size of the `users` collection in the `fullstack` database
```
> use fullstack
switched to db fullstack
> db.users.count()
100
```
Get the first document
```JSON
> db.users.findOne()
{
	"_id" : ObjectId("5d998e44fb4cdf93870c74e6"),
	"gender" : "female",
	"name" : {
		"title" : "Miss",
		"first" : "Gülay",
		"last" : "Junge"
	},
	"location" : {
		"street" : {
			"number" : 8604,
			"name" : "Marktplatz"
		},
		"city" : "Homburg",
		"state" : "Brandenburg",
		"country" : "Germany",
		"postcode" : 26354,
		"coordinates" : {
			"latitude" : "60.0048",
			"longitude" : "-80.8267"
		},
		"timezone" : {
			"offset" : "-3:00",
			"description" : "Brazil, Buenos Aires, Georgetown"
		}
	},
	"email" : "Gulay.Junge@example.com",
	"login" : {
		"uuid" : "ba4e68ed-fd10-4964-8ec5-a07fa68d642d",
		"username" : "goldenpeacock720",
		"password" : "dynamo",
		"salt" : "FeFsoLkU",
		"md5" : "f165e970fa27157b5a5bc89fff3d2ed1",
		"sha1" : "b244d8ebc5a003a9237422e79ceb2d43624f58a8",
		"sha256" : "3daaf79282f369eac3ff68bd07a1ac4962b2872723a2f5eb85d09ddee4d8d521"
	},
	"dob" : {
		"date" : "1948-01-29T07:45:02.704Z",
		"age" : 71
	},
	"registered" : {
		"date" : "2009-04-29T13:36:11.872Z",
		"age" : 10
	},
	"phone" : "0370-1948139",
	"cell" : "0178-7897762",
	"id" : {
		"name" : "",
		"value" : null
	},
	"picture" : {
		"large" : "https://randomuser.me/api/portraits/women/66.jpg",
		"medium" : "https://randomuser.me/api/portraits/med/women/66.jpg",
		"thumbnail" : "https://randomuser.me/api/portraits/thumb/women/66.jpg"
	},
	"nat" : "DE"
}
```
Or getting the amount of female users
```
> db.users.find({"gender": "female"}).count()
47
```

The next part of the series will focus on setting up the REST API based on Play and Scala.
