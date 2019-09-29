---
layout: post
title: "Jekyll, part 7: Pagination"
date: 2019-09-29 10:07:46 +0200
categories: [jekyll,liquid]
---

## Preface
---
As the amount of posts grows, the amount of post on the index/front page grows as well, at least while using simple themes such as [Minima](https://github.com/jekyll/minima). In order to limit the amount of posts displayed on a single page, we need to add pagination. This functionality is available from some og the more advanced themes but again, Where is the fun in that?

## Setup
---
In order for this to work there is a little setup we need to do. We need to set a post per page limit and add a permalink defining the url each paginated page can be accessed at. Both these will be added to the *_config.yml*.

```yaml
paginate: 5
paginate_path: /posts/page:num
```

This will set the post per page limit to 5 and ensure that the paginated pages can be accessed at eg. `yourblog.domain/posts/page1`. We need to add a pagination plugin to the project as well. I'm using *jekyll-paginate* as this is supported by Github Pages. Add the plugin to the *Gemfile*:

```
group :jekyll_plugins do
  gem "jekyll-paginate"
end
```

From within the project folder run:

```
gem install jekyll-paginator
```

Finally, rename the *index.md* in the project root to *index.html*.

## Implement
---
We need to add the pagination functionality to the leyout template that generates the list of posts which is *_layouts/home.html*. This layout is in turn used from *index.html*. The original version of it can be seen below.

### The original template
---
```liquid
{% raw %}
---
layout: default
---

<div class="home">
  {%- if page.title -%}
    <h1 class="page-heading">{{ page.title }}</h1>
  {%- endif -%}

  {{ content }}

  {%- if site.posts.size > 0 -%}
    <h2 class="post-list-heading">{{ page.list_title | default: "Posts" }}</h2>
    <ul class="post-list">
      {%- for post in site.posts -%}
      <li>
        {%- assign date_format = site.minima.date_format | default: "%b %-d, %Y" -%}
        <span class="post-meta">{{ post.date | date: date_format }}</span>
        <h3>
          <a class="post-link" href="{{ post.url | relative_url }}">
            {{ post.title | escape }}
          </a>
        </h3>
        {%- if site.show_excerpts -%}
          {{ post.excerpt }}
        {%- endif -%}
      </li>
      {%- endfor -%}
    </ul>

    <p class="rss-subscribe">subscribe <a href="{{ "/feed.xml" | relative_url }}">via RSS</a></p>
  {%- endif -%}

</div>
{% endraw %}
```

### Current approach
---
Below are the current approach the template above implemented.
>* if page has title
>    * set page title
>* if site posts are non-empty
>    * for each post in site posts
>        * assign date
>        * display date
>        * display link to post
>        * if showing excerpt is enabled
>            * show excerpt
>* display rss feed

### New approach
---
Below are the new approach the template should implement.
>* if page has title
>    * set page title
>* if pagination is enabled
>    * assign posts from paginator to posts
>* else
>    * assign posts from site to posts
>* if posts are non-empty
>    * for each post in posts
>        * assign date
>        * display date
>        * display link to post
>        * if showing excerpt is enabled
>            * show excerpt
>         * display rss feed
>* if pagination is enabled
>   * if pagination has previous page
>     * display link to previous page
>     * display current page number of total page number
>     * if pagination has next page
>       * display link to next page
> * display rss feed

### The new template
---
Translating the pseudo code algorithm above, the template will now look like below.

```liquid
{% raw %}
---
layout: default
---

<div class="home">
  {%- if page.title -%}
    <h1 class="page-heading">{{ page.title }}</h1>
  {%- endif -%}

  {{ content }}

  {% if site.paginate %}
    {% assign posts = paginator.posts %}
  {% else %}
    {% assign posts = site.posts %}
  {% endif %}

  {%- if posts.size > 0 -%}
    <h2 class="post-list-heading">{{ page.list_title | default: "Posts" }}</h2>
    <ul class="post-list">
      {%- for post in posts -%}
      <li>
        {%- assign date_format = site.minima.date_format | default: "%b %-d, %Y" -%}
        <span class="post-meta">{{ post.date | date: date_format }}</span>
        <h3>
          <a class="post-link" href="{{ post.url | relative_url }}">
            {{ post.title | escape }}
          </a>
        </h3>
        {%- if site.show_excerpts -%}
          {{ post.excerpt }}
        {%- endif -%}
      </li>
      {%- endfor -%}
    </ul>
    {% if site.paginate %}
    <div class="pagination">
      {% if paginator.previous_page %}
        <a href="{{ paginator.previous_page_path }}" class="previous">&laquo; Previous</a>  &#8226;
      {% else %}
        <span class="previous">&laquo; Previous &#8226;</span>
      {% endif %}
      <span class="page_number">{{ paginator.page }} of {{ paginator.total_pages }}</span>
      {% if paginator.next_page %}
      &#8226; <a href="{{ paginator.next_page_path }}" class="next">Next &raquo;</a>
        {% else %}
        <span class="previous">&#8226; Next &raquo;</span>
      {% endif %}
    </div>
    {% endif %}
    <p class="rss-subscribe">subscribe <a href="{{ "/feed.xml" | relative_url }}">via RSS</a></p>
  {%- endif -%}

</div>
{% endraw %}
```

### Styling
---
In order to center the pagination links horizontally add the css below to */assets/main.css*.
```css
.pagination {
    text-align: center;
}
```

And we're done. Enjoy.

The next part of the series, [Jekyll, part 8: Displaying categories on posts]({% post_url 2019-09-29-jekyll-part-8-displaying-categories-on-posts %}), will focus on displaying categories on posts.
