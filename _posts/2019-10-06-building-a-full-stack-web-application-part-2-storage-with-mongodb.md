---
layout: post
title: "Building a full stack web application, part 2: Storage with MongoDB"
date: 2019-10-06 08:30:00 +0200
categories: [mongodb,docker]
---

## Preface
---
In this part I'll create a MongoDB 4.2.0 container via docker-compose for the storage layer and import some previously generated data. I'm assuming you already intalled Docker and Docker Compose as instructed in [part 1]({% post_url 2019-10-05-building-a-full-stack-web-application-part-1-introduction-and-setup %})

## The database container
---
Docker-compose is a utility use to define and run multi container applications. The compose file is written in [YAML](https://en.wikipedia.org/wiki/YAML). Via the command `docker-compose` one can i.e. build, start or stop the containers defined with the file all at once rather than having to do for each indivudual container.

### Database initialization
While running in a container MongoDB will on first startup if the instance contains no databases, look for supported initalization scripts in the folder `/docker-entrypoint-initdb.d/` and execute them. This comes in handy for us as we can use this for some inital database configuration and even load data into it if we want. For the database I want to add a unique index for the email attribute which ensures no two users will have the same email address. I want some initial data in the collection as well and while I could add it to the initialization script I'll rather do it via a seed container. Create the initialization script `mongodb/mongo-init.js` with this content
```javascript
db = db.getSiblingDB('fullstack');
db.users.createIndex({"email" : 1, unique: 1});
```
This selects the database `fullstack` and on the collection `users` in `fullstack` adds an unique index on the attribute `email`.

### Dockerfile
Within the project's mongodb folder create a file named `Dockerfile` containing
```docker
FROM mongo:4.2.0
COPY mongo-init.js /docker-entrypoint-initdb.d/mongo-init.js
```
This will use the mongo 4.2.0 image as base for the image we're building and copy the database initialization script into the container. Docker-compose cannot copy files which is why we're doing it here.

### docker-compose.yml
Within the project's mongodb folder create a file named `docker-compose.yml`. One could argue that writing a compose file is not needed at this point but we're going use it for the seed container and use in the next part also so we might as well do it right away. The content of the file should be what is listed below. Keep in mind that Yaml is pretty particular about indenting and whitespace.
```yml
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
* services: contains definitions for one or more service (containers)
  * fullstack_mongodb: the name of the service being defined
  * build: specifies build directory containing the Dockerfile to build the service from
  * container_name: the name of the running container
  * ports: mapping bewteen host and container ports (specified on the line below)

## The data seed container
---
As mentioned in the first part I used randomuser to generate some initial data that can be found [here](https://github.com/ndlarsen/fullstack-webapp-guide/blob/master/mongodb-seed/users.json). Save the data file as `mongodb-seed/users.json`. We just need to copy the seed data file into the seed container instance, wait for the MongoDB container to be ready and import it into the running instance of MongoDB in the other container. So we need to write the Dockerfile for the seed data container and a script to execute inside the seed container which imports the data when the MongoDB container is be ready.

### The script
The script will continuously poll the MongoDB container on port 27017 until it's ready, thus halting the script and keeping the seed container alive until the import can be run. Save it as `mongodb-seed/wait_for_mongodb.sh`.

```bash
#!/bin/sh

echo "Running wait script"

: ${MONGODB_HOST=fullstack_mongodb}
: ${MONGODB_PORT=27017}

until nc -z $MONGODB_HOST $MONGODB_PORT
do
    echo "Waiting for Mongo ($MONGODB_HOST:$MONGODB_PORT) to start..."
    sleep 0.5
done

echo "Importing data"

mongoimport --host fullstack_mongodb --db fullstack --mode upsert --upsertFields=email,login.username --collection users --type json --file users.json --jsonArray

if [ $? -eq 1 ]
then
   echo "Import failed"
   exit 1
fi

echo "Import succeeded"

eval "$*"

```

### Dockerfile
The Dockerfile just uses a basic container image, adds the tools it needs, copies the data and import script over and executes the import script. Save as `mongodb-seed/Dockerfile`

```docker
FROM alpine:3.9

RUN apk add --update mongodb-tools netcat-openbsd
COPY ./wait_for_mongodb.sh .
COPY ./users.json .
RUN chmod 700 ./wait_for_mongodb.sh

ENTRYPOINT ["/bin/sh", "./wait_for_mongodb.sh"]
```


## Build, run, stop
---

At this point you should be able to build and run the containers by
```
$ docker-compose up -d
```

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
The containers can be stopped and removed by
```
$ docker-compose down
```
Both `start` and `up` can be run with a `-d` flag to detach and run in the background. Run `man docker-compose` or `docker-compose --help` for more information.

## Checking the MongoDB content
---
Let's just for good measure check if the database actually contains data. You can connect directly to the MongoDB shell inside the contaiern by running
```
$ docker exec -it fullstack_mongodb /bin/bash -c mongo
```
This will output some text
```
MongoDB shell version v4.2.0
connecting to: mongodb://127.0.0.1:27017/?compressors=disabled&gssapiServiceName=mongodb
Implicit session: session { "id" : UUID("8175bc01-950c-4ce7-9cf7-f6ba2f5c62f3") }
MongoDB server version: 4.2.0
Welcome to the MongoDB shell.
For interactive help, type "help".
For more comprehensive documentation, see
	http://docs.mongodb.org/
Questions? Try the support group
	http://groups.google.com/group/mongodb-user
Server has startup warnings: 
2019-10-19T20:40:41.322+0000 I  STORAGE  [initandlisten] 
2019-10-19T20:40:41.322+0000 I  STORAGE  [initandlisten] ** WARNING: Using the XFS filesystem is strongly recommended with the WiredTiger storage engine
2019-10-19T20:40:41.322+0000 I  STORAGE  [initandlisten] **          See http://dochub.mongodb.org/core/prodnotes-filesystem
2019-10-19T20:40:42.327+0000 I  CONTROL  [initandlisten] 
2019-10-19T20:40:42.327+0000 I  CONTROL  [initandlisten] ** WARNING: Access control is not enabled for the database.
2019-10-19T20:40:42.327+0000 I  CONTROL  [initandlisten] **          Read and write access to data and configuration is unrestricted.
2019-10-19T20:40:42.327+0000 I  CONTROL  [initandlisten] 
---
Enable MongoDB's free cloud-based monitoring service, which will then receive and display
metrics about your deployment (disk utilization, CPU, operation statistics, etc).

The monitoring data will be available on a MongoDB website with a unique URL accessible to you
and anyone you share the URL with. MongoDB may use this information to make product
improvements and to suggest MongoDB products and deployment options to you.

To enable free monitoring, run the following command: db.enableFreeMonitoring()
To permanently disable this reminder, run the following command: db.disableFreeMonitoring()
---
```
and leave you at a promt looking like this
```
>
```
To get the size of the `users` collection in the `fullstack` database
```
> use fullstack
switched to db fullstack
> db.users.count()
20
```
Get the first document
```JSON
> db.users.findOne()
{
	"_id" : ObjectId("5dab74caebad0c410309d7ce"),
	"gender" : "female",
	"name" : {
		"title" : "Miss",
		"first" : "Nina",
		"last" : "Sutton"
	},
	"location" : {
		"street" : {
			"number" : 5603,
			"name" : "Harrison Ct"
		},
		"city" : "Lancaster",
		"state" : "Utah",
		"country" : "United States",
		"postcode" : 63734,
		"coordinates" : {
			"latitude" : "61.9761",
			"longitude" : "142.5816"
		},
		"timezone" : {
			"offset" : "0:00",
			"description" : "Western Europe Time, London, Lisbon, Casablanca"
		}
	},
	"email" : "nina.sutton@example.com",
	"phone" : "(086)-093-1748",
	"picture" : {
		"large" : "https://randomuser.me/api/portraits/women/12.jpg",
		"medium" : "https://randomuser.me/api/portraits/med/women/12.jpg",
		"thumbnail" : "https://randomuser.me/api/portraits/thumb/women/12.jpg"
	},
	"nat" : "US"
}

```
Or getting the amount of female users
```
> db.users.count({"gender": "female"})
9
```

The next part of the series will focus on setting up the REST API based on Play and Scala.
