---
layout: post
title: "Jekyll, part 3: Creating posts"
date: 2019-09-25 20:29:15 +0200
categories: [jekyll]
---

## Preface
As you already know, the *_posts* folder will contain your posts. The file content should honour a specific format and it should be named by following
convention `year-month-day-title-of-post.markup`, eg. `2019-09-25-jekyll-part-3-creating-posts.md`. As far as I currently know, Jekyll only supports
Markdown and HTML as content markup languages.

## Front Matter
The header of the file is called *front matter* and is used to define the meta of the post.
```
---
layout: post
title: "Jekyll, part 3: Creating posts"
date: 2019-09-25 20:29:15 +0200
categories: [jekyll]
---
```
The categories attribute could as well have been category or tags. As far as Jekyll is concerned, it'll be handled the same way except taht tags cannot be part of the url. Ommitting the square brackets is allod if there's only one category present. If there are several, seperate them by commas. Both a catogoris and a tags attribute can be present simultaneously.

## Content
The content goes below the Front Matter and in this case the content is written in Markdown. You'll likely recognize it from README.md's on github and the like.
```
## Preface
As you already know, the *_posts* folder will contain your posts. The file content should honour a specific format and it should be named by following
convention `year-month-day-title-of-post.markup`, eg. `2019-09-25-jekyll-part-3-creating-posts.md`. As far as I currently know, Jekyll only supports
Markdown and HTML as content markup languages.
```
As in [part 2]({% post_url 2019-09-24-jekyll-part-2-generating-a-barebones-page %}) you can preview the post by running
```
jekyll serve -w
```
from within the project folder and there you go.

The next part will focus on using [github pages](https://pages.github.com/) as the hosting platform for your jekyll site.
