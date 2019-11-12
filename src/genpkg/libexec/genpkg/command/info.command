#!/usr/bin/env bash

info_entrypoint() {
    try_source "$PKGFILE"
    #TODO
    #lint_entrypoint
    for var in "name" \
                   "description" \
                   "version" \
                   "homepage" \
                   "license"
    do
        local var_holder="${!var}"
        if [[ ${#var_holder} -ne 0 ]]
        then
            echo "$var=$var_holder"
        fi
    done
    for var in "provides" \
                   "replaces" \
                   "conficts" \
                   "sources" \
                   "sha1" \
                   "sha256" \
                   "sha512" \
                   "noextract" \
                   "dependencies" \
                   "build_dependencies"

    do
        # shellcheck disable=1087
        local name_holder="$var[@]"
        for elem in "${!name_holder}"
        do
            if [[ "${#elem}" -ne 0 ]]
            then
                echo "$var=$elem"
            fi
        done
    done
}

info_desc() {
    echo "Read and output informations about a package from its Pkgfile"
}

info_help() {
    echo "genpkg $GENPKG_VERSION"
    echo
    info_desc
    echo
    echo "usage: genpkg [<options> ...] info"
    echo
    echo "Display information about a package in a \"KEY=VALUE\" format."
    echo
    echo
}
