---
layout: post
title: "Building a full stack web application, part 3: REST API via Play and Scala"
date: 2019-10-06 16:09:19 +0200
categories: [docker,play,scala]
---

## Preface
---
This part will focus on setting up a simple REST API with Play and Scala. Play is a MVC framework written in Scala and is capable of serving server side rendered web pages. However, as the UI will be written in Angular later, I will not use this functionality but rather use it for an intermediary layer between the Angular UI and MongoDB. I'm assuming you already installed java and sbt as instructed in [part 1]({% post_url 2019-10-05-building-a-full-stack-web-application-part-1-introduction-and-setup %}). I'm initially expecting to add CRUD User functionality to the API. This will be implemented as PUT, GET and DELETE endpoints with needed support functionality.

## Setting up the project
---
First we'll generate a basic Play project structure and afterwards we'll clean out the crud we do not need.

### The project skeleton
There is a [Giter8](http://www.foundweekends.org/giter8/) template available that supplies a barebones Play project. From within the overall project root run
```
$ sbt new playframework/play-scala-seed.g8
```
when prompted for a name enter `play-api` and whatever you choose when prompted for an organisation. This will leave you with two folders, `play-api` and `target`. Just delete the `target` directory. Enter the directory `play-api` and issue
```
$ sbt run
```
Eventually you'll see something similar to
```
--- (Running the application, auto-reloading is enabled) ---
[info] p.c.s.AkkaHttpServer - Listening for HTTP on /0:0:0:0:0:0:0:0:9000
(Server started, use Enter to stop and go back to the console...)
```

Test the running application
```none
$ curl -i http://localhost:9000
```
and if the output is looking like below all is well.
```none
HTTP/1.1 200 OK
Referrer-Policy: origin-when-cross-origin, strict-origin-when-cross-origin
X-Frame-Options: DENY
X-XSS-Protection: 1; mode=block
X-Content-Type-Options: nosniff
X-Permitted-Cross-Domain-Policies: master-only
Date: Mon, 14 Oct 2019 16:34:35 GMT
Content-Type: text/html; charset=UTF-8
Content-Length: 437

<!DOCTYPE html>
<html lang="en">
    <head>       
        <title>Welcome to Play</title>
        <link rel="stylesheet" media="screen" href="/assets/stylesheets/main.css">
        <link rel="shortcut icon" type="image/png" href="/assets/images/favicon.png">
    </head>
    <body>
  <h1>Welcome to Play!</h1>
      <script src="/assets/javascripts/main.js" type="text/javascript"></script>
    </body>
</html>
```

### A little clean up
Now, there are some bits we won't use and can delete.

As we're building a simple REST API we won't be serving assets. In `conf/routes` delete lines 9-10 containing
```
# Map static resources from the /public folder to the /assets URL path
GET     /assets/*file               controllers.Assets.versioned(path="/public", file: Asset)
```
as well as the folder `public`.

As we won't be serving webpages thus not building views, delete the folder `app/views`.

As we have no views to serve, in `app/controllers/HomeController.scala`, for now replace

```scala
    Ok(views.html.index())
```
with
```scala
    Ok
```
We won't be adding localization nor internationalization so delete the file `conf/messages`. While you're add it, rename the class `HomeController` to `UserController`. Remember to update `conf/routes` and rename `app/controllers/HomeController.scala` as well.
You should now the able to run the application again. Test it again with
```none
$ curl -i http://localhost:9000
```
This time no content is returned and the response should look like below
```
HTTP/1.1 200 OK
Referrer-Policy: origin-when-cross-origin, strict-origin-when-cross-origin
X-Frame-Options: DENY
X-XSS-Protection: 1; mode=block
X-Content-Type-Options: nosniff
X-Permitted-Cross-Domain-Policies: master-only
Date: Mon, 14 Oct 2019 16:40:04 GMT
Content-Length: 0
```

## Adding the MongoDB module
---
For communication with the database we'll be using a Play module called [ReactiveMongo](http://reactivemongo.org). Using this we won't have to deal with e.g. establishing connection to the database and other things like that. In `build.sbt` change line 10-11 from

```scala
libraryDependencies += guice
libraryDependencies += "org.scalatestplus.play" %% "scalatestplus-play" % "4.0.3" % Test
```
into
```scala
libraryDependencies ++= Seq(
  guice,
  "org.scalatestplus.play" %% "scalatestplus-play" % "4.0.3" % Test,
  "org.reactivemongo" %% "play2-reactivemongo" % "0.18.7-play27"
)
```
This will add the module as a dependency to the project. To `conf/application.conf` add the following 
```conf
# The mongo module
play.modules.enabled += "play.modules.reactivemongo.ReactiveMongoModule"
# Url of the MongoDB instance
mongodb.uri = "mongodb://localhost:27017/fullstack"
```
The first line will tell Play the actually enable the module and the last is defining the url of the database instance in our Docker container from [part 2]({% post_url 2019-10-06-building-a-full-stack-web-application-part-2-storage-with-mongodb %})

## Data conversion
---
In order to get data from and put data into the database we're going to deserialize the JSON we recieve from the database into objects and serialize the objects back into JSON again before providing it the the API client. Yes, in this case it's a bit contrived and unneeded as we're not processing the data within the API but for the purpose of making a simple example it's fine. For this `JSON -> object -> JSON` process to work, we need to model the data as classes and ensure we have some formatters to handle the conversion.

#### The models
The overall data structure and relations are outlined in [part 1]({% post_url 2019-10-05-building-a-full-stack-web-application-part-1-introduction-and-setup %}#data-structure). Rather that model the entire structure, we'll keep it to user, name, part of the location, street, and picture. I placed all models inside `app/models/UserModels.scala` abd they look like this:

```scala
package models

import java.util.UUID

case class Name(first: String, last: String, title: String)
case class Street(number: Int, name: String)
case class Location(street: Street, city: String, state: String, postcode: Int, country: String)
case class Picture(medium: String, large: String, thumbnail: String)
case class User(gender: String, name: Name, location: Location, email: String, phone: String, picture: Picture, nat: String)
```

There's really not a whole lot to say about them besides the fact that they're [case classes](https://www.geeksforgeeks.org/scala-case-class-and-case-object/). If you're not familiar with case classes they'll probably look odd to you but think of them as classes on steroids comming with a lot of very nice functionality by default. The case class by default provides getters, methods for toString hashCode and structural equality, a companion object with an apply method that removes the need for the new keyword and fuctionality to pattern match and then some. Other than for practise, I cannot recall having written a regular class in scala.

#### The JSON formatters
Both Play and ReactiveMongo comes with functionality built in to (de)serialize JSON. For this we'll be using functionality from ReactiveMongo as I do not see any reason to write any from scratch. For this to work there is a caveat, though. The class attributes needs to be named *exactly* the same as the attributes from the JSON you want to extract. Our formatters will look like below and are placed in `app/models/JsonFormats.scala` 
```scala
package models

import play.api.libs.json.{Json, OFormat}

object JsonFormats {
  implicit val streetFormat: OFormat[Street] = Json.format[Street]
  implicit val locationFormat: OFormat[Location] = Json.format[Location]
  implicit val nameFormat: OFormat[Name] = Json.format[Name]
  implicit val pictureFormat: OFormat[Picture] = Json.format[Picture]
  implicit val userFormat: OFormat[User] = Json.format[User]
}

```

### Extending the controller
As mentioned earlier we'll be leveraging functionality from ReactiveMongo to handle database connection and such. This means we need to extend our `UserController` with `MongoController` and `ReactiveMongoComponents` as well as passing an instance of `ReactiveMongoApi` as an argument to it. In `app/controllers/UserController.scala` replace
```scala
class UserController @Inject()(cc: ControllerComponents) extends AbstractController(cc) {
```
with
```scala
import play.modules.reactivemongo._

class UserController @Inject()(cc: ControllerComponents,
                               val reactiveMongoApi: ReactiveMongoApi)
                              (implicit ec: ExecutionContext)
  extends AbstractController(cc)
    with MongoController
    with ReactiveMongoComponents {
```

### Database connection
The `MongoController` we're extending our controller with, supplies an attribute `database` which we can use to connect to our database and get a reference to the collection we want. In `app/controllers/UserController.scala` add
```scala
import reactivemongo.play.json.collection._
```
and
```scala
private val collection = database.map(_.collection[JSONCollection]("users"))
```

## GET /user/email/:param
---
For our first bit of functionality we need to add an endpoint we can query. This will be composed of an route in `conf/routes` and a method in `app/controllers/UserController.scala` which the route will call. As the controller method need to do several things, let's break it a bit more down. First getting or establishing a connection to the database, then getting a handle to the right collection, then create an object respresenting the query we are doing, then executing the query in the database which returns a cursor and finally converting the content of the cursor, if any, into a result to return. So, overall:
* get connection to db (done above)
* get a handle to the collection (done above)
* create query object
* execute query
* convert return value

### Getting data
As we now have a handle to our database collection we can do queries. For this we're using the method
```scala
find[S, J](selector: S, projection: Option[J])
```
Import
```scala
import reactivemongo.api.Cursor
import reactivemongo.play.json._
```

This method takes a selector, our query, and an optional projection, defining the values from the result we want, as parameters. Both the selector and projection are in the form of a JSON object. In this case we want all users with a specific email address and all values from the result. This means our method should probably take the email as an argument. 

```scala
def findByEmail(email: String): Action[AnyContent] = Action.async {
```
It also means that our selection will contain the argument email and our projection will be empty
```scala
      val selection = Json.obj({"email" -> email})
      val projection = Option.empty[JsObject]
```
At this point we need to get the collection handle, execute our query and get the cursor
```scala
      val cursor = collection.map {
        _.find(selection, projection).cursor[User]()
      }
```
Finally we need to convert the result into JSON and return it.
```scala
      val futureUsersList = cursor.flatMap(_.collect[Seq](-1, Cursor.FailOnError[Seq[User]]()))
      futureUsersList.map {
        case Nil => NotFound
        case users: Seq[User] => Ok(Json.toJson(users))
      }
}
```
Rearranging the code the result is
```scala
  def findByEmail(email: String): Action[AnyContent] = Action.async {
    val selection = Json.obj("email" -> email)
    getData(selection)
  }

  private def getData(selection: JsObject): Future[Result] = {
    val cursor = doQuery(selection)
    cursorToUserSeq(cursor).map {
      case Nil => NotFound
      case users: Seq[User] => Ok(Json.toJson(users))
    }
  }

  private def doQuery(selection: JsObject) = collection.map {
    val projection = Option.empty[JsObject]
    _.find(selection, projection).cursor[User]()
  }

  private def cursorToUserSeq(cursor: Future[Cursor[User]]): Future[Seq[User]] = {
    cursor.flatMap(_.collect[Seq](-1, Cursor.FailOnError[Seq[User]]()))
  }
```
Add these methods to `app/controllers/UserController.scala`.

### Routing
The last bit we need is the define an actual endpoint to query. In `conf/routes` replace
```conf
GET     /                          controllers.UserController.index
```
with
```conf
GET     /user/:email         controllers.UserController.findByEmail(email)
```
This enables an endpoint `/user/:email` accepting GET requests with a parameter. This route will call the method `findByEmail(email: String)` in the controller `UserController` with the given argument.

### Test it
Getting a existent user
```
$ $ curl -i localhost:9000/user/email/nina.sutton@example.com

HTTP/1.1 200 OK
Referrer-Policy: origin-when-cross-origin, strict-origin-when-cross-origin
X-Frame-Options: DENY
X-XSS-Protection: 1; mode=block
X-Content-Type-Options: nosniff
X-Permitted-Cross-Domain-Policies: master-only
Date: Sun, 20 Oct 2019 08:51:35 GMT
Content-Type: application/json
Content-Length: 486

[{"gender":"female","name":{"first":"Nina","last":"Sutton","title":"Miss"},"location":{"street":{"number":5603,"name":"Harrison Ct"},"city":"Lancaster","state":"Utah","postcode":63734,"country":"United States"},"email":"nina.sutton@example.com","phone":"(086)-093-1748","picture":{"medium":"https://randomuser.me/api/portraits/med/women/12.jpg","large":"https://randomuser.me/api/portraits/women/12.jpg","thumbnail":"https://randomuser.me/api/portraits/thumb/women/12.jpg"},"nat":"US"}]
```
and getting a nonexistent user
```
$ curl -i localhost:9er/email/nonexistent@example.com
HTTP/1.1 404 Not Found
Referrer-Policy: origin-when-cross-origin, strict-origin-when-cross-origin
X-Frame-Options: DENY
X-XSS-Protection: 1; mode=block
X-Content-Type-Options: nosniff
X-Permitted-Cross-Domain-Policies: master-only
Date: Sun, 20 Oct 2019 08:53:25 GMT
Content-Length: 0
```
By the way, you can remove
```scala
  /**
   * Create an Action to render an HTML page.
   *
   * The configuration in the `routes` file means that this method
   * will be called when the application receives a `GET` request with
   * a path of `/`.
   */
  def index() = Action { implicit request: Request[AnyContent] =>
    Ok(views.html.index())
  }
```
from `app/controllers/UserController.scala` if you haven't already.

## PUT /user/
---
The PUT endpoint will provide functionality to both create a new user as well as update en existing user. For this to work we need to parse the request body, validate that the body content conforms the our model structure and finally insert it into the database.
* parse body
* validate body content
* create selection object
* insert into database

### Putting data
For convenience I've divided the functionality into a public method and a private helper. The main responsibility of the public method is to validate the content of the request body and act accordingly.
```scala
  def insertUser(): Action[JsValue] = Action.async(parse.json) { request =>
    request.body.validate[User] match {
      case error: JsError => Future.successful(BadRequest("Invalid input format"))
      case success: JsSuccess[User] => doInsert(success.value).flatten
    }
  }
```

The helper method will build our selctor and modifier for the update. The update is also passed `upsert = true` to ensure the document is created if no existing match is found and `multi = false` in order to only update a single document.
```scala
  private def doInsert(user: User) = collection.map {
    val selector = Json.obj("email" -> user.email)
    val modifier = Json.obj(
      "$set" -> Json.toJson(user)
    )
    _.update(ordered = false).one(selector, modifier, upsert = true, multi = false).map { writeResult =>
      if (writeResult.ok) {
        Created
      } else {
        InternalServerError(writeResult.toString)
      }
    }
  }
```
### Routing
And the route as the final piece.
```
PUT     /user/                    controllers.UserController.insertUser()
```

### Test it
With valid data
```
$ curl -i -X PUT http://localhost:9000/user/ -H 'Content-Type: application/json' -d '{"gender":"female","name":{"title":"Miss","first":"Gladys","last":"Andrews"},"location":{"street":{"number":6151,"name":"Spring Hill Rd"},"city":"Princeton","state":"Florida","country":"United States","postcode":83886},"email":"gladys.andrews@example.com","phone":"(689)-603-9010","picture":{"large":"https://randomuser.me/api/portraits/women/35.jpg","medium":"https://randomuser.me/api/portraits/med/women/35.jpg","thumbnail":"https://randomuser.me/api/portraits/thumb/women/35.jpg"},"nat":"US"}'

HTTP/1.1 201 Created
Referrer-Policy: origin-when-cross-origin, strict-origin-when-cross-origin
X-Frame-Options: DENY
X-XSS-Protection: 1; mode=block
X-Content-Type-Options: nosniff
X-Permitted-Cross-Domain-Policies: master-only
Date: Sat, 19 Oct 2019 22:39:56 GMT
Content-Length: 0
```
and with invalid data
```
curl -i -X PUT http://localhost:9Type: application/json' -d '{}'
HTTP/1.1 400 Bad Request
Referrer-Policy: origin-when-cross-origin, strict-origin-when-cross-origin
X-Frame-Options: DENY
X-XSS-Protection: 1; mode=block
X-Content-Type-Options: nosniff
X-Permitted-Cross-Domain-Policies: master-only
Date: Sat, 19 Oct 2019 22:42:39 GMT
Content-Type: text/plain; charset=UTF-8
Content-Length: 20

Invalid input format
```

## DELETE /user/email/:email
---
The delete method is fairly straightforward

```scala
  def deleteUser(email: String): Action[AnyContent] = Action.async {
    collection.map{
      val selector = Json.obj({"email" -> email})
      _.delete(ordered = false).one(selector).map{ deleteResult =>
        if (deleteResult.ok) {
          Ok
        } else {
          InternalServerError(deleteResult.toString)
        }
      }
    }.flatten
  }
```

### Routing
```
DELETE  /user/email/:param        controllers.UserController.deleteUser(param)
```

### Test it
Delete a nonexistent user
```
$ curl -i -X DELETE localhost:9000/user/email/nonexistent@example.com

HTTP/1.1 200 OK
Referrer-Policy: origin-when-cross-origin, strict-origin-when-cross-origin
X-Frame-Options: DENY
X-XSS-Protection: 1; mode=block
X-Content-Type-Options: nosniff
X-Permitted-Cross-Domain-Policies: master-only
Date: Sun, 20 Oct 2019 10:02:12 GMT
Content-Length: 0
```
Check is a specific user exists
```
$ curl -i -X GET http://localhost:9000/user/email/gladys.andrews@example.com

HTTP/1.1 404 Not Found
Referrer-Policy: origin-when-cross-origin, strict-origin-when-cross-origin
X-Frame-Options: DENY
X-XSS-Protection: 1; mode=block
X-Content-Type-Options: nosniff
X-Permitted-Cross-Domain-Policies: master-only
Date: Sat, 19 Oct 2019 23:22:23 GMT
Content-Length: 0
```
Add a user to delete
```
$ curl -i -X PUT http://localhost:9000/user/ -H 'Content-Type: application/json' -d '{"gender":"female","name":{"title":"Miss","first":"Gladys","last":"Andrews"},"location":{"street":{"number":6151,"name":"Spring Hill Rd"},"city":"Princeton","state":"Florida","country":"United States","postcode":83886},"email":"gladys.andrews@example.com","phone":"(689)-603-9010","picture":{"large":"https://randomuser.me/api/portraits/women/35.jpg","medium":"https://randomuser.me/api/portraits/med/women/35.jpg","thumbnail":"https://randomuser.me/api/portraits/thumb/women/35.jpg"},"nat":"US"}'

HTTP/1.1 201 Created
Referrer-Policy: origin-when-cross-origin, strict-origin-when-cross-origin
X-Frame-Options: DENY
X-XSS-Protection: 1; mode=block
X-Content-Type-Options: nosniff
X-Permitted-Cross-Domain-Policies: master-only
Date: Sat, 19 Oct 2019 23:21:20 GMT
Content-Length: 0
```
Confirm the user was added
```
$ curl -i -X GET http://localhost:9000/user/email/gladys.andrews@example.com

HTTP/1.1 200 OK
Referrer-Policy: origin-when-cross-origin, strict-origin-when-cross-origin
X-Frame-Options: DENY
X-XSS-Protection: 1; mode=block
X-Content-Type-Options: nosniff
X-Permitted-Cross-Domain-Policies: master-only
Date: Sat, 19 Oct 2019 23:21:42 GMT
Content-Type: application/json
Content-Length: 498

[{"gender":"female","name":{"first":"Gladys","last":"Andrews","title":"Miss"},"location":{"street":{"number":6151,"name":"Spring Hill Rd"},"city":"Princeton","state":"Florida","postcode":83886,"country":"United States"},"email":"gladys.andrews@example.com","phone":"(689)-603-9010","picture":{"medium":"https://randomuser.me/api/portraits/med/women/35.jpg","large":"https://randomuser.me/api/portraits/wondlarsen@master:~/src/fullstack-webapp-guide$ 
```
Delete the recently added user
```
$ curl -i -X DELETE http://localhost:9000/user/email/gladys.andrews@example.com

HTTP/1.1 200 OK
Referrer-Policy: origin-when-cross-origin, strict-origin-when-cross-origin
X-Frame-Options: DENY
X-XSS-Protection: 1; mode=block
X-Content-Type-Options: nosniff
X-Permitted-Cross-Domain-Policies: master-only
Date: Sat, 19 Oct 2019 23:21:56 GMT
Content-Length: 0
```
Confirm that the user was deleted
```
$ curl -i -X GET http://localhost:9000/user/email/gladys.andrews@example.com

HTTP/1.1 404 Not Found
Referrer-Policy: origin-when-cross-origin, strict-origin-when-cross-origin
X-Frame-Options: DENY
X-XSS-Protection: 1; mode=block
X-Content-Type-Options: nosniff
X-Permitted-Cross-Domain-Policies: master-only
Date: Sat, 19 Oct 2019 23:22:23 GMT
Content-Length: 0
```

This is the basic fuctionality. I extended the controller with a few methods and rearranged some code within it. The final result is [here](https://github.com/ndlarsen/fullstack-webapp-guide/tree/master/play-api)

## Dockerize it
---
As a final task we need to build a container with the application. There are a quite a few different approaches to this and for the purpose of example I just chose to copy the sources into a cotainer and run the project in production mode via sbt. For this to work we need to
* add an application secret to the application
* write a Dockerfile
* add a service to the docker-compose.yml

### Application secret
The purpose of the application secret is described [here](https://www.playframework.com/documentation/2.7.x/ApplicationSecret) as well as best practises. Now, We're breaking a rather important best practise by placing the application secret in the configuration file but for the this purpose it does not really matter. Don't do this on production, though. In `conf/application.conf` add
```conf
play.http.secret.key = "some-secret"
```

### Dockerfile

```

```