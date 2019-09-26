---
layout: post
title: "Jekyll, part 4: Hosting at Github Pages"
date: 2019-09-26 19:08:40 +0200
categories: [jekyll,github]
---

## Preface
Creating and running the site locally is all fine well but the point of making it all is probably to share it with others. Some sort of hosting is needed for
that and while there are several options available, using Github Pages is easy, free and tailored for Jekyll. All we need to do is just create a respository and push the project to Githuib Pages via git.

## Creating the repository
You'll need a Github account for this so go create it you don't already have one. Go create a new repository, note that the repository for the site must be named by following convention: `username.github.io`. The repository shoud be public, not have a README, .gitignore or license.

## Pushing the code
Change into the project folder and initialize it as a git repository if you haven't already by running
```
git init
git remote add origin https://github.com/username/username.github.io # or use the ssh version if you prefer
```
When ready to push your site to the repo by running
```
git add .
git commit -m "Write a commit message here such as: Initial commit"
git push
```
Your new site should be available at https://username.github.io shortly after.
