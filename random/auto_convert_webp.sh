#!/bin/bash


####################
( #-START-SUBSHELL-#
####################

replace() {
    [[ ! -f "${1}" ]] && return 1

    local new_file="${1/[.]webp/${2}.png}"

    printf "\t\t\t\tin: %s, out: %s\n" "${1}" "${new_file}"
    if dwebp "${1}" -o "${new_file}" &>/dev/null && [[ -f "${new_file}" ]] ; then
        return 0
    fi
    return 2
}

main_replace() {
    local dir="${1:-"${HOME}/Pictures"}"
    local append="${2:-""}"
    cd "${dir}" || return 1
    while IFS= read -r -d $'\0' ifile ; do
        replace "${ifile}" "${append}"
        case $? in
            0) trash-put "${ifile}"
        ;;  1) echo "Not found: ${ifile}"
        ;;  *) echo "Error: _${ifile}_"
        ;; esac
    done < <(find . -type f -name "*.webp" -print0)
}
#dir="${1:-"${HOME}/Pictures"}"
#append="${2:-""}"
#cd "${dir}" || return 1
#find . -type f -name "*.webp" -print0
main_replace "${@}"

####################
) #---END-SUBSHELL-#
####################

#"
#"
