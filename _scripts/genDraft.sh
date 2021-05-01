#!/bin/bash

# Generates a draft post for jekyll honoring the jekyll naming format.

exit_error(){
    echo "$1"
    exit 1
}

print_help(){
    echo "Usage:"
    echo -e "\t`basename "$0"` \"{title}\" \"{category1}\" \"{optionalCategory1}\" ... \"{optionalCategoryN}\""
    echo ""
}

join_by(){
    local IFS="$1"
    shift
    echo "$*"
}

if [ $# -lt 2 ] || ( [ $# == 1 ] && [ "$1" == "help" ] )
then
    print_help && exit
fi

[ $# -lt 2 ] && exit_error "not enough arguments"

dd=`date +%Y-%m-%d`
dt=`date +'%H:%M:%S %z'`
layout=post

filename=$(echo $1 | sed -e 's/./\L&/g' -e 's/\s/-/g' -e 's/[^[:alnum:]-]//g')

categories=`join_by "," "${@:2}"`

cat << END > "$dd-$filename.md"
---
layout: $layout
title: "$1"
date: $dd $dt
categories: [$categories]
---

## Preface
---
END
