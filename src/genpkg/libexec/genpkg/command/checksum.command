checksum_entrypoint() {
    if ! lint_entrypoint
    then
        die "genpkg: checksum: $PKGFILE isn't valid"
    fi
    if [[ "${#sources[@]}" -eq 0 ]]
    then
        log "genpkg: checksum: $PKGFILE has no sources"
        return
    fi
    tmp_dir=$(mktemp -d)
    for idx in "${!sources[@]}"
    do
        is_dir="false"
        if [[ ${sources[$idx]} == git* ]]
        then
            log "${sources[$idx]}: Git source, skiping..."
            is_dir="true"
        else
            get_source "${sources[$idx]}" "$tmp_dir"
            filename="$tmp_dir/$(ls "$tmp_dir")"
            base_filename=$(basename "$filename")
        fi
        for hash_method in "sha1" "sha256" "sha512"
        do
            local var_name="${hash_method}[$idx]"
            if [[ "$is_dir" == "true" ]]
            then
                eval "${var_name}"=SKIP
            else
                local var_name="${hash_method}[$idx]"
                if ! check=$(shasum -a "${hash_method:3}" "$filename" | cut -d " " -f 1)
                then
                    rm -rf "$tmp_dir"
                    die "genpkg: checksum: error while calculating $hash_method for $base_filename"
                fi
                eval "${var_name}"="$check"
            fi
        done
        rm -rf "$filename"
    done
    rm -rf "$tmp_dir"
    echo -n "sources=("
    for idx in "${!sources[@]}"
    do
        echo -n "\"${sources[$idx]}\""
        if (( idx + 1 != ${#sources[@]} ))
        then
            echo -n " "
        fi
    done
    echo ")"
    for hash_method in "sha1" "sha256" "sha512"
    do
        local var_name="${hash_method}[*]"
        echo "$hash_method=(${!var_name})"
    done
}

checksum_desc() {
    echo "Give you checksum for your sources"
}

checksum_help() {
    echo "genpkg $GENPKG_VERSION"
    echo
    checksum_desc
    echo
    echo "usage: genpkg [<options> ...] checksum"
    echo
    echo "Give you checksum (sha1, sha256 and sha512) of all the sources"
    echo "in a given Pkgfile"
    echo
    echo
}
