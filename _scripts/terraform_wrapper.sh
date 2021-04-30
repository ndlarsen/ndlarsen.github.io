#!/bin/bash -e

SCRIPT_NAME=$(basename "$0")

function help {
  echo
  echo -e "a simple 'update-alternatives' wrapper for terraform which allows manipulating terraform binaries for the given user"
  echo
  echo -e "Usage: $SCRIPT_NAME arg1 <arg2>"
  echo -e "  install <terraform_bin_to_add>  <priority> - installs the given alternative with given priority"
  echo -e "  config                                     - for configuring the current default alternative"
  echo -e "  remove <terraform_bin_alternative>         - removes the given alternative"
  echo -e "  display                                    - display current available configurations"
  echo
}

ALT_DIR="$HOME/.local/etc/alternatives"
ADMIN_DIR="$HOME/.local/var/lib/alternatives"
BIN_DIR="$HOME/bin"
TARGET=$BIN_DIR/terraform
NAME=terraform

[ ! -d "$ALT_DIR" ] && mkdir -p "$ALT_DIR"
[ ! -d "$ADMIN_DIR" ] && mkdir -p "$ADMIN_DIR"
[ ! -d "$BIN_DIR" ] && mkdir -p "$BIN_DIR"

function updateAlt {
  update-alternatives --altdir "$ALT_DIR" --admindir "$ADMIN_DIR" "$@"
} 

case "$1" in
  install)
    if [ -z "$2" ]
    then
      echo
      echo "no alternative supplied"
      exit
    fi

    if [ -z "$3" ]
    then
      echo
      echo "no priority for alternative supplied"
      exit
    fi

    BIN_WITH_PATH="$BIN_DIR/$2"
    PRIO="$3"
    updateAlt --install "$TARGET" "$NAME" "$BIN_WITH_PATH" "$PRIO"
    ;;
  config)
    updateAlt --config "$NAME" 
    ;;
  remove)
    if [ -z "$2" ]
    then
      echo
      echo "no path to alternative supplied"
      exit
    fi
    BIN_WITH_PATH="$BIN_DIR/$2"
    updateAlt --remove "$NAME" "$BIN_WITH_PATH"
    ;;
  display)
    updateAlt --display "$NAME"
    ;;
  *)
    help
    ;;
esac
