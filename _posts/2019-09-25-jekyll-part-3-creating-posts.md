---
layout: post
title: "Jekyll, part 3: Creating posts"
date: 2019-09-25 20:29:15 +0200
categories: [jekyll]
---

## Preface
---
As you already know, the *_posts* folder will contain your posts. The file contents should honour a specific format and it should be named by following convention `year-month-day-title-of-post.markup`, eg. `2019-09-25-jekyll-part-3-creating-posts.md`. As far as I currently know, Jekyll only supports Markdown and HTML as contents markup languages.

## Front Matter
---
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

## Contents
---
The contents goes below the Front Matter and in this case the contents is written in Markdown. You'll likely recognize it from README.md's on github and the like.

```
## Preface
As you already know, the *_posts* folder will contain your posts. The file contents should honour a specific format and it should be named by following convention `year-month-day-title-of-post.markup`, eg. `2019-09-25-jekyll-part-3-creating-posts.md`. As far as I currently know, Jekyll only supports Markdown and HTML as contents markup languages.
```

As in [part 2]({% post_url 2019-09-24-jekyll-part-2-generating-a-barebones-page %}) you can preview the post by running the command below from within the project folder and there you go.

```
jekyll serve -w
```

## Drafts
---
From time to time might want to keep drafts in the project without having them displayed. Create a *_drafts* folder with the project and place your draft in there. Jekyll won't build those when building or previewing the side unless explicitly told to as below.
```
jekyll serve -w --draft
```

## Skeleton post
---
I made a simple shell script to generate a basic skeleton post. I initially placed the script inside the *_scripts* folder in order to not display it. By running it:

```
./getDraft.sh "Post title" JekyllCategory OptionCategory
```

will output a file in the current folder which honours the naming convention with a Front Matter similar to the following:

```
---
layout: post
title: "First post"
date: 2019-09-26 20:01:41 +0200
categories: [SomeCategory,OptionalCategory]
---
```

Use the script if you wish. It's available [here](https://github.com/ndlarsen/ndlarsen.github.io/blob/master/_scripts/genDraft.sh)

The next part will focus on using [Github Pages](https://pages.github.com/) as the hosting platform for your jekyll site and can be found here: [Jekyll, part 4: Hosting at Github Pages]({% post_url 2019-09-26-jekyll-part-4-hosting-at-github-pages %})
