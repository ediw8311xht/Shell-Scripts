#!/usr/bin/env bash

main_make_run_cpp() {
    local outfile="/tmp/cpp_tmp.out"
    local exit_code
    local run_file=""
    local info_file="./.my_info"
    local include_files=()

    # Functions
    __check_files() {
        if [[ "${#}" -le 0 ]] ; then
            return 0
        elif [[ ! -f "${1}" ]] ; then 
            printf "File Not Found: '%s'\n" "${1}" >&2
            exit 1
        else
            __check_files "${@: 2}"
        fi
    }
    __handle_args() {
        while [[ "${#}" -gt 0 ]] ; do
            if [[ "${1##*.}" =~ [.].*info$ ]] ; then
                info_file="${1}"
                shift 1
            elif [[ "${1,,}" =~ ^-[a-z]$ ]] ; then
                include_files+=( "${1}" "${2}" )
                shift 2
            elif [[ -n "${1}" ]] && __check_files "${@}" ; then
                run_file="${*}"
                return 0
            elif ! run_file="$(fd -e .cpp -e .h)" ; then
                echo "No .cpp/.h files found" >&2
                return 1
            else
                return 0
            fi
        done
    }

    __handle_args "${@}"
    if [[ -f "${info_file}" ]] ; then
        xargs g++ -std="c++23" @"${info_file}" -o "${outfile}" <<< "${run_file}"
    else
        xargs g++ -std="c++23" "${include_files[@]}" -o "${outfile}" <<< "${run_file}" 
    fi

    exit_code="$?"

    if [[ "${exit_code}" -eq 0 ]] &&  [[ -f "${outfile}" ]] ; then
        "${outfile}"
    fi
}

main_make_run_cpp "${@}"
