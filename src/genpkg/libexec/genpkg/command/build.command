build_entrypoint() {
    local WANT_LIST_OPTIONS="false"
    local WANT_LIST_DEPS="false"
    local OUTPUT="default"
    local TEMPDIR
    given_options=()

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
        build_list_options
        return
    fi
    while [[ "$#" -ne 0 ]]
    do
        local found=1
        given_options+=("$1")
        # shellcheck disable=2154
        for option in "${options[@]}"
        do
            if [[ $option == "$1" ]]
            then
                found=0
            fi
        done
        if [[ $found -eq 1 ]]
        then
            # shellcheck disable=2154
            die "genpkg: build: $1: unknown option for $name"
        fi
        shift
    done
    if [[ "$WANT_LIST_DEPS" == true ]]
    then
        build_list_deps
        return
    fi
    if [[ "$OUTPUT" != default ]]
    then
        echo "output = $OUTPUT"
    fi
    TEMPDIR=$(mktemp -d -t genpkg)
    push_d "$TEMPDIR"
    #build_do_the_build
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

build_list_options() {
    # shellcheck disable=2154
    if ! declare -p options > /dev/null 2>&1 || [[ "${#options[@]}" -eq 0 ]]
    then
        echo "$name has no options"
    else
        echo "Options of $name:"
        for index in "${!options[@]}"
        do
            echo "  ${options[$index]}: ${options_description[$index]}"
        done
    fi
}

build_list_deps() {
    local deps=()
    local build_deps=()
    for given_option in "${given_options[@]}"
    do
        given_option=${given_option//-/_}
        local var_name="option_${given_option}_deps"
        if declare -p "$var_name" > /dev/null 2>&1
        then
            var_name="${var_name}[@]"
            for dep in "${!var_name}"
            do
                deps+=("$dep")
            done
        fi
        var_name="option_${given_option}_build_deps"
        if declare -p "$var_name" > /dev/null 2>&1
        then
            var_name="${var_name}[@]"
            for build_dep in "${!var_name}"
            do
                build_deps+=("$build_dep")
            done
        fi
    done
    # shellcheck disable=2154
    if declare -p "dependencies" > /dev/null 2>&1 && [[ "${#dependencies[@]}" -ne 0 ]]
    then
        deps+=("$dependencies")
    fi
    # shellcheck disable=2154
    if declare -p "build_dependencies" > /dev/null 2>&1 && [[ "${#build_dependencies[@]}" -ne 0 ]]
    then
        build_deps+=("$build_dependencies")
    fi
    IFS=" " read -r -a deps <<< "$(tr ' ' '\n' <<< "${deps[@]}" | sort -u | tr '\n' ' ')"
    IFS=" " read -r -a build_deps <<< "$(tr ' ' '\n' <<< "${build_deps[@]}" | sort -u | tr '\n' ' ')"
    if [[ "${#deps[@]}" -eq 0 && "${#build_deps[@]}" -eq 0 ]]
    then
        echo "No dependencies for $name ${given_options[*]}"
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
