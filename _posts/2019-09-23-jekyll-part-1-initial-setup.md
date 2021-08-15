---
layout: post
title:  "Jekyll, part 1: Initial setup"
date:   2019-09-23 19:46:00 +0200
categories: [jekyll]
---

## Preface
---
I'm assuming you're running a Linux distribution. In my case it's Ubuntu 20.04. If you're running another distribution
you should be able to figure out what commands your preferred distributions package managers equivalent commands are.

Now, there are a jekyll package available from the repositories and while it might work just fine for your needs, it is
quite outdated and as such we're going the gem route.

## Dependencies and initial setup
---
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
If for some reason you get an error as this:
```
Traceback (most recent call last):
	10: from /home/ndlarsen/gems/bin/jekyll:23:in `<main>'
	 9: from /home/ndlarsen/gems/bin/jekyll:23:in `load'
	 8: from /home/ndlarsen/gems/gems/jekyll-4.1.1/exe/jekyll:11:in `<top (required)>'
	 7: from /home/ndlarsen/gems/gems/jekyll-4.1.1/lib/jekyll/plugin_manager.rb:52:in `require_from_bundler'
	 6: from /usr/lib/ruby/2.7.0/bundler.rb:149:in `setup'
	 5: from /usr/lib/ruby/2.7.0/bundler/runtime.rb:26:in `setup'
	 4: from /usr/lib/ruby/2.7.0/bundler/runtime.rb:26:in `map'
	 3: from /usr/lib/ruby/2.7.0/bundler/spec_set.rb:147:in `each'
	 2: from /usr/lib/ruby/2.7.0/bundler/spec_set.rb:147:in `each'
	 1: from /usr/lib/ruby/2.7.0/bundler/runtime.rb:31:in `block in setup'
/usr/lib/ruby/2.7.0/bundler/runtime.rb:312:in `check_for_activated_spec!': You have already activated mercenary 0.4.0, but your Gemfile requires mercenary 0.3.6. Prepending `bundle exec` to your command may solve this. (Gem::LoadError)
```
then do a
```
bundle exec jekyll -v
```

That's it. Jekyll is installed and ready to use.

The next part of the series,
[Jekyll, part 2: Generating a barebones page]({% post_url 2019-09-24-jekyll-part-2-generating-a-barebones-page %}), will
focus on getting a template site up and running.
