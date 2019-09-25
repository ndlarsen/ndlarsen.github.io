---
layout: post
title:  "Jekyll, part 1: Initial setup"
date:   2019-09-23 19:46:00 +0200
categories: [jekyll]
---

## Preface
I'm assuming you're running a Linux distribution. In my case it's Ubuntu 18.04. If you're running another distribution you should be able to figure out what commands your preferred distributions package managers equivalent commands are.

Now, there are a jekyll package available from the repositories and while it might work just fine for your needs, it is quite outdated and as such we're going the gem route.

## Dependencies and initial setup
Install ruby:
```
sudo apt-get install ruby-full
```

In order to avoid having to run related jekyll/gem commands via sudo:
```
echo -e 'export GEM\_HOME="$HOME/gems"\n'export PATH="$HOME/gems/bin:$PATH"'' >> ~/.profile
source ~/.bashrc
```
Install jekyll:
```
gem install jekyll bundler
```
For good measure, run:
```
jekyll -v
```
The output should be similar to
```
jekyll 4.0.0
```
That's it. Jekyll is installed and ready to use.

Check out the next part here: [Jekyll, part 2: Generating a barebones page]({% post_url 2019-09-24-jekyll-part-2-generating-a-barebones-page %})
