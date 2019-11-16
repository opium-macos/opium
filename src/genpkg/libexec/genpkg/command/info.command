info_entrypoint() {
    if ! lint_entrypoint > /dev/null
    then
        die "genpkg: build: $PKGFILE isn't valid"
    fi
    for var_name in "name" \
                   "description" \
                   "version" \
                   "homepage" \
                   "license" \
                   "nocd"
    do
        if declare -p "$var_name" > /dev/null 2>&1
        then
            echo "$var_name=${!var_name}"
        fi
    done
    for var_name in "provides" \
                   "replaces" \
                   "conficts" \
                   "sources" \
                   "sha1" \
                   "sha256" \
                   "sha512" \
                   "noextract" \
                   "dependencies" \
                   "build_dependencies" \
                   "options" \
                   "options_descriptions"

    do
        if declare -p "$var_name" > /dev/null 2>&1
        then
            local array="${var_name}[@]"
            for elem in "${!array}"
            do
                if [[ "${#elem}" -ne 0 ]]
                then
                    echo "$var_name=$elem"
                fi
            done
        fi
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
