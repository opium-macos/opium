build_entrypoint() {
    local WANT_LIST_OPTIONS="false"
    local WANT_LIST_DEPS="false"
    local TEMPDIR

    if ! lint_entrypoint
    then
        die "genpkg: build: $PKGFILE isn't valid"
    fi
    while [[ "$#" -ne 0 && "$1" == -* ]]
    do
        local case="$1"
        case "$case" in
            --)
                break
                ;;
            -l|--list-options)
                WANT_LIST_OPTIONS=true
                ;;
            -d|--list-dependencies)
                WANT_LIST_DEPS=true
                ;;
            -o|--output)
                shift
                if [[ "$#" -eq 0 ]]
                then
                    die "genpkg: build: missing argument for $case"
                fi
                OUTPUT="$1"
                ;;
            -o=*|--output=*)
                OUTPUT=$(echo "$1" | cut -d "=" -f 2)
                ;;
            -o*)
                OUTPUT=${1:2}
                ;;
            *)
                die "genpkg: build: $case: unknown option"
                ;;
        esac
        shift
    done
    if [[ "$1" == "--" ]]
    then
        shift
    fi
    if [[ "$WANT_LIST_OPTIONS" == true && "$WANT_LIST_DEPS" == true ]]
    then
        die "genpkg: build: you can't use --list-options and --list-dependencies together"
    fi
    if [[ "$WANT_LIST_OPTIONS" == true ]]
    then
        list_options
        return
    fi
    while [[ "$#" -ne 0 ]]
    do
        if ! option_exist "$1"
        then
            die "genpkg: build: $1: unknown option for $name"
        fi
        given_options+=("$1")
        shift
    done
    if [[ "$WANT_LIST_DEPS" == true ]]
    then
        list_deps
        return
    fi
    if [[ "$OUTPUT" != default ]]
    then
        echo "output = $OUTPUT"
    fi
    TEMPDIR=$(mktemp -d -t genpkg)
    push_d "$TEMPDIR"
    do_the_build
    pop_d
    rm -rf "$TEMPDIR"
}

build_desc() {
    echo "Build a package from a Pkgfile"
}

build_help() {
    echo "genpkg $GENPKG_VERSION"
    echo
    build_desc
    echo
    echo "usage: genpkg [<options> ...] build [<build options> ...] [--] [<package options> ...]"
    echo
    echo "Generate a package, in a tar.gz format, using a Pkgfile, containing all the files"
    echo "and informations neccessary for its installation by opium. Each package have differents options"
    echo "run \"genpkg build -l\" to have a list of avaible options for the package your trying to build"
    echo
    echo
    echo "Build options:"
    echo
    echo "-o file, -ofile, -o=file, --output file, --output=file"
    echo "  Build the package in file.pkg.tar.gz (default to ./name-version[-options].pkg.tar.gz)"
    echo
    echo "-l, --list-options"
    echo "  List package options then exit"
    echo
    echo "-d, --list-dependencies"
    echo "  List package dependencies then exit"
}

list_options() {
    # shellcheck disable=2154
    if ! declare -p options > /dev/null 2>&1 || [[ "${#options[@]}" -eq 0 ]]
    then
        echo "$name has no options"
    else
        echo "Options of $name:"
        for ((i = 0; i < option_counter; i += 1))
        do
            echo "  $(get_option "${i},name"): $(get_option "${i},description")"
        done
    fi
}


list_deps_for_opt() {
    local type=""
    local deps=""
    if [[ "$#" -lt 1 || "$#" -gt 2 ]]
    then
        die "genpkg: build: internal error: wrong number of argument"
    fi
    if [[ "$#" -eq 2 ]]
    then
        type="${1}_"
        shift
    fi
    if option_exist "$1"
    then
        local nb_deps
        nb_deps="$(get_option "$1" "nb_${type}dependencies")"
        for ((i = 0; i < nb_deps; i += 1))
        do
            deps+="$(get_option "$1" "${type}dependencies,${i}")"
            if ((i + 1 != nb_deps))
            then
                deps+=" "
            fi
        done
    fi
    echo "$deps"
}

list_deps() {
    local deps=("${dependencies[@]}")
    local build_deps=("${build_dependencies[@]}")
    for opt in "${given_options[@]}"
    do
        local opt_deps
        local opt_build_deps
        opt_deps=$(list_deps_for_opt "$opt")
        opt_build_deps=$(list_deps_for_opt "build" "$opt")
        deps=("${deps[@]}" "${opt_deps[@]}")
        build_deps=("${build_deps[@]}" "${opt_build_deps[@]}")
    done
    IFS=" " read -r -a deps <<< "$(tr ' ' '\n' <<< "${deps[@]}" | sort -u | tr '\n' ' ')"
    IFS=" " read -r -a build_deps <<< "$(tr ' ' '\n' <<< "${build_deps[@]}" | sort -u | tr '\n' ' ')"
    if [[ "${#deps[@]}" -eq 0 && "${#build_deps[@]}" -eq 0 ]]
    then
        echo "No dependencies for $name ${given_options[*]}"
        return
    fi
    if [[ "${#deps[@]}" -ne 0 ]]
    then
        echo "Dependencies of $name ${given_options[*]}"
        echo "  ${deps[*]}"
    fi
    if [[ "${#build_deps[@]}" -ne 0 ]]
    then
        echo "Build dependecies of $name ${given_options[*]}"
        echo "  ${build_deps[*]}"
    fi
}

# shellcheck disable=2154
do_the_build() {
    if declare -p sources > /dev/null 2>&1
    then
        mkdir temp
        for idx in "${!sources[@]}"
        do
            local source="${sources[$idx]}"
            local curl_opt="-O"
            local filename
            local uri
            if [[ "$source" == *::* ]]
            then
                filename="${source%%::*}"
                uri="${source##*::}"
                curl_opt="-o$filename"
            else
                uri="${source}"
            fi
            push_d temp
            case $uri in
                https://*|http://*|ftp://*)
                    log "Downloading ${filename:-$uri}"
                    debug "Running 'curl $curl_opt $uri'"
                    curl "$curl_opt" "$uri"
                    ;;
                git://*)
                    log "Cloning ${filename:-$uri}"
                    debug "Running 'git clone $uri $filename'"
                    git clone "$uri" $filename
                    ;;
                *)
                    log "Copy/pasting ${filename:-$uri}"
                    debug "Running cp '$GENPKG_DIR/$uri" "${filename:-.}'"
                    cp "$GENPKG_DIR/$uri" "${filename:-.}"
                    ;;
            esac
            filename=${filename:-$(ls)}
            pop_d
            mv "temp/${filename}" .
            if can_be_extracted "$filename"
            then
                extract "$filename"
                rm -rf "$filename"
            fi
        done
        rmdir temp
        log "Building ${name} ${given_options[*]}"

        out_dir=$(mktemp -d ./out.XXXXXXX)
        #TODO better function overwrite / chroot (cd, push_d, etc...)
        mkdir "$out_dir/prefix" "$out_dir/sysroot" "$out_dir/app"
        #TODO

        if ! CFLAGS="-I${OPIUM_PREFIX}/include" \
                 CXXFLAGS="-I${OPIUM_PREFIX}/include" \
                 LDFLAGS="-L${OPIUM_PREFIX}/lib" \
                 MAKEFLAGS="-j" \
                 prefix="$(getpath "$out_dir/prefix")" \
                 app="$(getpath "$out_dir/app")" \
                 sysroot="$(getpath "$out_dir/sysroot")" \
                 build
        then
                rm -rf "$out_dir"
                rm -rf "$TEMPDIR"
                die "genpkg: build: error while builing"
        fi
        #TODO still digusting, but better
        cd "$TEMPDIR" ||
            {
                rm -rf "$out_dir"
                rm -rf "$TEMPDIR"
                die "genpkg: build: error while going back to build directory"
            }
        log "Finished build of ${name} ${given_options[*]}"
        if ! declare -p OUTPUT > /dev/null 2>&1
        then
            OUTPUT="$BASE_PWD/${name}${given_options[*]}.pkg.tar.gz"
        elif [[ "$OUTPUT" == ./* ]]
        then
            OUTPUT="${OUTPUT:2}"
            OUTPUT="$BASE_PWD/$OUTPUT"
        elif [[ "$OUTPUT" != */* ]]
        then
            OUTPUT="$BASE_PWD/$OUTPUT"
        fi
        tar czf "$OUTPUT" -C "$out_dir" "prefix" "app" "sysroot" ||
            {
                rm -rf "$out_dir"
                rm -rf "$TEMPDIR"
                die "genpkg: build: error while creating $OUTPUT"
            }
        rm -rf "$out_dir"
    fi
}
