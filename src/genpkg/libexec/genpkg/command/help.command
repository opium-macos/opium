#!/usr/bin/env bash

help_entrypoint() {
    if [ "$#" -eq 0 ]
    then
        usage
    else
        if ! is_genpkg_command "$1"
        then
            die "genpkg: unknown command: $1"
        else
            "$1_help"
        fi
    fi
}

help_desc() {
    echo "Display help about the program or a specific command"
}

help_help() {
    echo "genpkg $GENPKG_VERSION"
    echo
    help_desc
    echo
    echo "usage: genpkg [<options> ...] help [command]"
    echo
    echo "Display help for the given command."
    echo "if no command is provided, display global usage."
    echo
    echo
}
