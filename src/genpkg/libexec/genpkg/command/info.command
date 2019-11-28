info_entrypoint() {
    if ! lint_entrypoint
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
                   "no_extract" \
                   "dependencies" \
                   "build_dependencies"
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
    for ((i = 0; i < option_counter; i += 1))
    do
        local nb_deps
        local nb_build_deps

        echo "option_${i}_name=$(get_option "${i},name")"
        echo "option_${i}_description=$(get_option "${i},description")"
        nb_deps=$(get_option "${i},nb_dependencies")
        for ((j = 0; j < nb_deps; j += 1))
        do
            echo "option_${i}_dependencies_${j}=$(get_option "${i},dependencies,${j}")"
        done
        nb_build_deps=$(get_option "${i},nb_build_dependencies")
        for ((j = 0; j < nb_build_deps; j += 1))
        do
            echo "option_${i}_build_dependencies_${j}=$(get_option "${i},build_dependencies,${j}")"
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
