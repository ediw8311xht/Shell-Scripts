#!/bin/bash

getfrom() {
    local a
    a="$(gzip -k -d "${1}" -c | cut -d ',' -f 5)"
    echo "${a}"

    if [[ "${a}" =~ ^[0-9.]+$  ]] ; then
        echo "${a}" >> "$HOME/.config/polybar/my_modules/log.txt"
        printf '%.2f\n' "${a}"
        return 0
    else
        return 1
    fi
}

myfunc() {
    wget -S                                             \
        --header='Accept: */*'                          \
        --header='Accept-Encoding: gzip, deflate, br'   \
        --header='Accept-Language: en-US,en;q=0.9'      \
        --header='Connection: keep-alive'               \
        --header='Host: proxy.kitco.com'                \
        --header='Origin: https://www.kitco.com'        \
        --header='Referer: https://www.kitco.com/'      \
        --header='Sec-Fetch-Dest: empty'                \
        --header='Sec-Fetch-Mode: cors'                 \
        --header='Sec-Fetch-Site: same-site'            \
        --header='Sec-GPC: 1'                           \
        --header='User-Agent: Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/103.0.5060.114 Safari/537.36' \
        "https://proxy.kitco.com/getPM?symbol=${1}"     \
        --output-document="/tmp/${1}.gz"                \
        2> /dev/null                                    \
    && [[ -f "/tmp/${1}.gz" ]]                          \
    && getfrom "/tmp/${1}.gz"                           \
    && return 0                                         \
    || return 1
}

main() {
    if ! [[ "${1}" =~ (AG|AU|PD|PT) ]] ; then
        return 1
    fi

    for _ in {1..10} ; do
        while ! myfunc "${1}" ; do
            sleep 2
        done
    done
}

main "${@}"
