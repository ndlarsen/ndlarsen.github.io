#!/bin/bash

# Generates a draft post for jekyll honoring the jekyll naming format.

exit_error() {
    echo "$1"
    exit 1
}

print_help(){
    echo "Usage:"
    echo -e "\t`basename "$0"` \"{title}\" \"{category1}\" \"{category2}\" ... \"{categoryN}\""
    echo ""
}

join_by (){
    local IFS="$1"
    shift
    echo "$*"
}

[ $# -lt 2 ] && [ "$1" == "help" ] && print_help && exit

[ $# -lt 2 ] && exit_error "not enough arguments"

dd=`date +%Y-%m-%d`
dt=`date +'%H:%M:%S %z'`
layout=post

categories=`join_by "," ${@:2}`

FRONT_MATTER="---
layout: $layout
title: $1
date: $dd $dt
categories: [$categories]
---
"

echo "$FRONT_MATTER" > "$dd-$1.md"
echo "$FRONT_MATTER"
