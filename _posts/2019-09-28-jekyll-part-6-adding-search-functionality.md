---
layout: post
title: "Jekyll, part 6: Adding search functionality."
date: 2019-09-28 09:54:55 +0200
categories: [jekyll,liquid,javascript]
---

## Preface
---
As the amount of content on a site grows it becomes increasingly difficult to maintain some sort of insight in the total content or finding what you need. Adding search functionality will help alleviate that and in my opinion it's simply a necessity as well as a fundamental service to provide your users. As a jekyll site is generated, static and lacking server-side functionality, all search must be done client-side. Well, I guess you could add Google Custom Search but to be fair, why would you? Besides it being Google, the search functionality will depend on the availability of a third party which you might not want and you will have very little control over it.

There seem to be quite a few different approaches and solutions available, most relying on JavaScript implementations. Having looked at a few by now and wanting full post seach, I decided trying out [Lunr](https://lunrjs.com/) which some say is a [Solr](https://lucene.apache.org/solr/)-like search  implementation. Lunr is an inverted index and it can be compared to the index in the back of a book. Should you want a lille lighter implementation without full post search, [simple-jekyll-search](https://github.com/christian-fei/Simple-Jekyll-Search) seems to be a popular choice.

## Getting the source
---
At the time of writing, the latest version of Lunr id 2.3.6 and is available via npm and from [unpkg](https://upkg.com). Create a folder names *assets* within the site project and run:

```
wget -P assets/ https://unpkg.com/lunr@2.3.6/lunr.js
```

## The search index
---
Lunr needs the be fed all the data you want to be searchable in order to create the index. In our case the index will be based on a map-like structure of JavaScript objects representing our posts each consisting of an identifier and searchable fields. We need to generate the data list which we'll do when the site is build using Liquid templating and a bit of JavaScript. Populating the index will be done afterwards using JavaScript only.

### Overall approach
---
When page loads:
>* get all post for the site
>* for each post in posts
>   * add relevant post data to data list
>* when seach page loads add posts to index

Add a *search-index.js* to the *assets* folder in the project. This will contain the templating code to generate the data list as well as the index. The first code block is generating the data store. I know it looks a bit wierd with a Front Matter inside a JavaScript file but this is needed in order to have Jekyll picking up the file and compile it. The only thing this bit of code does, is creatig a JavaScript object with references named as the urls of our posts mapping to a representation of the post itself. This structure will come in handy later when we need to generate a list of links from the search result.

```javascript
{% raw %}
---
layout: null
---

const store = {
    {% for post in site.posts %}
    "{{ post.url | xml_escape }}": {
            "title": "{{ post.title | xml_escape }}",
            "categories": "{{ post.categories | join: ', ' }}",
            "content": {{ post.content | strip_html | jsonify }}
        }
        {% unless forloop.last %},{% endunless %}
    {% endfor %}
    };
{% endraw %}
```

The next part initializes the Lunar index with the post url as reference and populates the index with our data. The boost parameter at the title field tells Lunr to weight occurences of the search term higher if it occurs in the title.

```javascript
{% raw %}
const index = lunr(function(){
    this.ref("url");
    this.field("title", {
        boost: 10
    });
    this.field("categories");
    this.field("content");

    for(var key in store){
        this.add({
        "title": store[key].title,
        "url": key,
        "categories": store[key].categories,
        "content": store[key].content
        })
    }
});
{% endraw %}
```

## The search page
---
With the "search engine" complete we still need a place to execute the seach and view the results. Create a file named *search.html* in the project root. In that we'll add the HTML form to actually search with and import the remainder of the JavaScript which we'll write later. Jekyll should detect this file  automatically and add a link the index page.

```html
---
layout: default
title: Search
---

<script type="text/javascript" src="/assets/lunr.js"></script>
<script type="text/javascript" src="/assets/search-index.js"></script>
<script type="text/javascript" src="/assets/search-helper.js"></script>

<script>
    document.addEventListener('DOMContentLoaded', domOnLoadEventHandler);
</script>

<div>
    <form action="/search/" method="get">
        <input type="text" id="search-box" name="query" placeholder="Enter search criteria...">
        <input type="submit" value="search">
    </form>
</div>

<div id="result-container">
    <h1 id="search-results-h" class="post-list-heading" style="display: none"></h1>
</div>
```

## Gluing it all together
---
In order for us to actually execute a search and display the results, we need to add some helper functions to hold it all together. Place the script below in */assets/search-helper.js*

### Overall approach
---
When the page is done loading and the [DOM](https://developer.mozilla.org/en-US/docs/Web/API/Document_Object_Model/Introduction) is ready:

>* get search terms from url
>* if no search terms
>   * then exit
>* else
>   * do search
>* if search has no results
>   * then display "no results found"
>* else
>   * for each result in result
>       * generate link to post

```javascript
function domOnLoadEventHandler(event) {
    const urlSearchParams = new URLSearchParams(window.location.search);
    const searchTerm = urlSearchParams.getAll("query").join(" ");

    if(searchTerm === null || searchTerm.trim() === ""){
        return;
    }

    var searchResult = index.search(searchTerm);

    if(searchResult.length === 0){
        noResultsFound();
    }
    else{
        displayResults(searchResult);
    }
}

function noResultsFound(){
    setTextAndDisplay("No results found.")
}

function displayResults(results){
    setTextAndDisplay("Results:")
    
    const h1 = document.getElementById("search-results-h");
    const ul = document.createElement("ul")

    if(h1 === null || h1 == undefined){
        throw new Error("Unable to locate element")
    }

    results.forEach(function(result){
        var item = store[result.ref];
        var li = document.createElement("li");
        var link = document.createElement("a");
        link.setAttribute("href", result.ref);
        link.innerHTML = item.title;
        li.appendChild(link);
        ul.appendChild(li);
    });

    h1.parentElement.appendChild(ul);
}

function setTextAndDisplay(text){
    if(typeof text !== "string"){
        throw new TypeError("Supplied argument is not a string");
    }
    const h = document.getElementById("search-results-h");

    if(h === null || h == undefined){
        throw new Error("Unable to locate element")
    }

    h.innerText = text;
    h.style.display = "block";
}
```
That's it, try it out.

The next part of the series, ["Jekyll, part 7: Pagination"]({% post_url /2019-09-29-jekyll-part-7-pagination %}), will focus on adding pagination to the site.
