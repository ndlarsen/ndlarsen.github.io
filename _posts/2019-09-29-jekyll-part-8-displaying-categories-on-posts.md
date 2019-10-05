---
layout: post
title: "Jekyll, part 8: Displaying categories on posts"
date: 2019-09-29 17:00:38 +0200
categories: [jekyll,liquid]
---

## Preface
---
This post will show you how to display the categories of a post on the post's page. I'm assuming you already added categories to your posts, it not I wrote a little about it [here]({% post_url 2019-09-26-jekyll-part-5-adding-a-categories-page %}). An obvious thing to do would be generating a link for each category pointing to an overview page for that specific category. Rather that doing that in this post I'm going to have the category link point to the category specific part of the [categories page]({% link categories.html %}) I created in an [earlier post]({% post_url 2019-09-26-jekyll-part-5-adding-a-categories-page %}). Perhaps I'll get back to individual category pages in a post later, I haven't fully decided yet.

## Generate the links
---
There isn't much to doing this. We just need to generate the links on the post template.
### Overall approach
>* for category in post categories
>   * display link

Told you is was simple. This translates to this simple bit of Liquid code that should be added to *_layouts/post.html* just under the if statement handling author name. now, to be fair, I added a litte to make it prettier.

```liquid
{% raw %}
{% if page.categories %}
    <div>
    Categories: [
    {% for category in page.categories %}
        <a href="{{site.baseurl}}/categories/#{{category|slugize}}">
            {{category}}
        </a>{% unless forloop.last %}, {% endunless %}
    {% endfor %}]
{% else %}Uncategorized
    </div>
{% endraw %}
```
## Update the categories page
---
This bit is pretty simple as well.
### Adding section ids
 We need to update the categories page template with ids for the section links, you know the one I mentioned I made in [this post]({% post_url 2019-09-26-jekyll-part-5-adding-a-categories-page %}). There is nothing to this part either, in the *categories.html* just make sure to add an category id to the div containing the specific category list, so change:
 
 ```liquid{% raw %}
<div>
    <h3 class="post-list-heading">{{ category | first | capitalize }}</h3>
{% endraw %}```

into:

 ```liquid{% raw %}
<div id="{{ category.first }}">
    <h3 class="post-list-heading">{{ category | first | capitalize }}</h3>
{% endraw %}```

And there you have it.
