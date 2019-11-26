lint_entrypoint() {
    declare -i ret=0
    if [[ ! -f "$PKGFILE" ]]
    then
        die "genpkg: lint: $PKGFILE: no such file"
    fi
    if ! bash_lint=$(/bin/bash -n "$PKGFILE" 2>&1) || [[ $(echo -n "$bash_lint" | wc -l ) -ne 0 ]]
    then
        die "genpkg: lint: $PKGFILE: invalid bash file"
    fi
    try_source "$PKGFILE"
    for var in "name" "version"
    do
        if ! declare -p "$var" > /dev/null 2>&1
        then
            ((ret += 1))
            log "genpkg: lint: $var is unset"
        fi
    done
    for var in "name" "description" "homepage" "version" "license"
    do
        if declaration=$(declare -p "$var" 2>&1) && ! [[ "$declaration" =~ "declare --" || "$declaration" =~ "declare -r" ]]
        then
            ((ret += 1))
            log "genpkg: lint: $var isn't a string"
        fi
    done
    for var in "provides" "replaces" "conflicts" "sources" "sha1" "sha256" "sha512" "noextract" "dependencies" "build_dependencies"
    do
        if declaration=$(declare -p "$var" 2>&1) && ! [[ "$declaration" =~ "declare -a" || "$declaration" =~ "declare -ar" ]]
        then
            ((ret += 1))
            log "genpkg: lint: $var isn't an array"
        fi
    done
    # shellcheck disable=2154
    if declare -p "sources" > /dev/null 2>&1
    then
        for hash in "sha1" "sha256" "sha512"
        do
            local hash_length
            hash_length=$(eval echo \$\{\#$hash\[\@\]\})
            if declare -p "$hash" > /dev/null 2>&1 && [[ "${#sources[@]}" -gt "$hash_length" ]]
            then
                ((ret += 1))
                log "genpkg: lint: there is less hash than sources ($hash)"
            fi
        done
    fi
    return $ret
}

lint_desc() {
    echo "Check a Pkgfile syntaxe"
}

lint_help() {
    echo "genpkg $GENPKG_VERSION"
    echo
    lint_desc
    echo
    echo "usage: genpkg [<options> ...] lint"
    echo
    echo "Display syntaxe error in a Pkgfile, report one error per line (if not fatal)"
    echo
    echo
}
