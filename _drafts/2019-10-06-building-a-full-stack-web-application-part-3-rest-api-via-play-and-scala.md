---
layout: post
title: "Building a full stack web application, part 3: REST API via Play and Scala"
date: 2019-10-06 16:09:19 +0200
categories: [docker,play,scala]
---

## Preface
---
This part will focus on setting up a simple REST API with Play and Scala. Play is a MVC framework written in Scala and is capable of serving server side rendered web pages. However, as the UI will be written in Angular later, I will not use this functionality but rather use it for an intermediary layer between the Angular UI and MongoDB. I'm assuming you already installed java and sbt as instructed in [part 1]({% post_url 2019-10-05-building-a-full-stack-web-application-part-1-introduction-and-setup %})

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
As an example we'll write functionality to find users by supplying an email address. In order to provide the result from the database we're going to deserialize the JSON we recieve from the database into objects and serialize the objects back into JSON again before providing it the the API client. Yes, in this case it's a bit contrived and unneeded as we're not processing the data within the API but for the purpose of making a simple example it's fine. For this `JSON -> object -> JSON` process to work, we need to model the data as classes and ensure we have some formatters to handle the conversion.

### The models
The overall data structure and relations are outlined in [part 1]({% post_url 2019-10-05-building-a-full-stack-web-application-part-1-introduction-and-setup %}#data-structure). Rather that modeling the entire structure, we'll keep it to user, name, part of the location, street, login and picture. I placed all models inside `app/models/UserModels.scala` abd hey look like this:

```scala
package models

import java.util.UUID

case class Name(first: String, last: String, title: String)
case class Street(number: Int, name: String)
case class Location(street: Street, city: String, state: String, postcode: Int, country: String)
case class Picture(medium: String, large: String, thumbnail: String)
case class User(gender: String, name: Name, location: Location, email: String, login: Login, phone: String, picture: Picture, nat: String)
```

There's really not a whole lot to say about them besides the fact that they're [case classes](https://www.geeksforgeeks.org/scala-case-class-and-case-object/). If you're not familiar with case classes they'll probably look odd to you but think of them as classes on steroids comming with a lot of very nice functionality by default. Other that for practise, I cannot recall having written a regular class in scala.

### The JSON formatters
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

## The first functionality
---
For our first bit of functionality we need to add an endpoint we can query. This will be composed of an route in `conf/routes` and a method in `app/controllers/UserController.scala` which the route will call. As the controller method need to do several things, let's break it a bit more down. First getting or establishing a connection to the database, then getting a handle to the right collection, then create an object respresenting the query we are doing, then executing the query in the database which returns a cursor and finally converting the content of the cursor, if any, into a result to return. So, overall:
* get connection to db
* get a handle to the collection
* create query object
* execute query
* convert return value

### Extending the controller
As mentioned earlier we'll be leveraging functionality from ReactiveMongo to handle database connection and such. This means we need to extend our `UserController` with `MongoController` and `ReactiveMongoComponents` as well as passing an instance of `ReactiveMongoApi` as an argument to it. In `app/controllers/UserController.scala` replace
```scala
class UserController @Inject()(cc: ControllerComponents) extends AbstractController(cc) {
```
with
```scala
class UserController @Inject()(cc: ControllerComponents,
                               val reactiveMongoApi: ReactiveMongoApi)
                              (implicit ec: ExecutionContext)
  extends AbstractController(cc)
    with MongoController
    with ReactiveMongoComponents {
```

### Database connection
The `MongoController` we're extending our controller with, supplies an attribute `database` which we can use to connect to our database and get a reference to the collection we want. In `app/controllers/UserController.scala` add
```
private val collection = database.map(_.collection[JSONCollection]("users"))
```
### Getting data
As we now have a handle to our database collection we can do queries. For this we're using the method
```scala
find[S, J](selector: S, projection: Option[J])
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
      futureUsersList.map { persons => Ok(Json.toJson(users)) }
}
```
Add this method to `app/controllers/UserController.scala`.

#### The route
The last bit we need is the define an actual endpoint to query. In `conf/routes` replace
```conf
GET     /                          controllers.UserController.index
```
with
```
GET     /user/email/:email         controllers.UserController.findByEmail(email)
```
This enables an endpoint `/user/email/:email` accepting GET requests with a parameter. This route will call the method `findByEmail(email: String)` in the controller `UserController` with the given argument.

#### Calling it
```
$ curl localhost:9000/users/email/hunter.schmidt@example.com

[{"gender":"male","name":{"first":"Hunter","last":"Schmidt","title":"Mr"},"location":{"street":{"number":9782,"name":"Taylor St"},"city":"Westminster","state":"Wisconsin","postcode":96090,"country":"United States"},"email":"hunter.schmidt@example.com","login":{"username":"browncat398","password":"home","salt":"Enp1s0Az","md5":"80716a5f6a1cb7829aafc39ffa618b78","sha1":"727d37e93af9435ec245b6b4c7a4c1f8cf0cb19e","sha256":"5a4e43592be06852f45082e7e9760d991be7e3cbd2195edc9139c6498d243a98"},"phone":"(814)-690-7782","picture":{"medium":"https://randomuser.me/api/portraits/med/men/90.jpg","large":"https://randomuser.me/api/portraits/men/90.jpg","thumbnail":"https://randomuser.me/api/portraits/thumb/men/90.jpg"},"nat":"US"}]
```

By the way, you can remove
```
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
from `app/controllers/UserController.scala` if you havn't already.

### Putting data

### Deleting data

### Updating data

These are the basics. I extended the controller with a few methods and rearranged some code within it. The final result is [here](https://github.com/ndlarsen/fullstack-webapp-guide/tree/master/play-api)

## Dockerize it
---
