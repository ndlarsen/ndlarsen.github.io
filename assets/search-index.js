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