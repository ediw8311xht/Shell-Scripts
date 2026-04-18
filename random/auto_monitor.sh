#!/bin/bash

get_resolution() {
    xrandr | grep "^${1} " | grep -Po "[0-9]+x[0-9]+"
}

get_monitors() {
    xrandr --listmonitors | grep -Po "(?<= )(HDMI|VGA|DVI|DP|TV|DisplayPort)[^\ ]+$"
}

rotate_m() {
    local ROTATE_MONITOR="${1}.*"
    if xrandr  -q | grep -Pio "${ROTATE_MONITOR}" | grep -Pioq '(left|right)[ \t]*[(]' ; then
        xrandr --output "${1}" --rotate "normal"
    else
        xrandr --output "${1}" --rotate "${2}"
    fi
    update_monitor_export
    "${HOME}/bin/feh_wallpaper.sh" --silent
}

set_xrec() {
    if [[ -z "${1}" ]] || [[ -z "${2}" ]] ; then return 1; fi
    local res
    local s=( "i3wm.${1}: ${2}" )

    mapfile -t -d $'\n' res < <(get_resolution "${2}" | tr "x" $'\n')
    if [[ "${#res[@]}" -eq 2 ]] ; then
        s+=( "i3wm.${1}_resx: ${res[0]}"
             "i3wm.${1}_resy: ${res[1]}" )
    fi
    printf "%s\n" "${s[@]}" ""
    printf "%s\n" "${s[@]}" >> "${HOME}/.Xresources"
}

handle_primary() {
    xrandr --output "${1}" --primary
    set_xrec "primary_monitor" "${1}"
    export "PRIMARY_MONITOR"="${1}"
}

handle_other() {
    set_xrec "other_monitor_${2}" "${1}"
    export "MON_${2}"="${1}"
}

update_monitor_export() {
    local ORDER_MONITORS=('DP' 'DisplayPort' 'HDMI' 'VGA' 'DVI' 'TV')
    local primary=''

    local MONS gmon lmon i
    MONS="$(get_monitors)"

    [[ ! -f "${HOME}/.Xresources" ]] && return 1

    sed -i '/^i3wm[.]\(primary\|other\)_monitor.*/Id' "${HOME}/.Xresources"

    for cm in "${ORDER_MONITORS[@]}" ; do
        gmon="$(grep -Fi "${cm}" <<< "${MONS}")"
        [[ -z "${gmon}" ]] && continue
        [[ -n "${lmon}" ]] && xrandr --output "${gmon}" --right-of "${lmon}"

        if [[ "${gmon}" = *"${primary}"* ]] ; then
            handle_primary "${gmon}"
        else
            handle_other "${gmon}" "$((++i))"
        fi
        lmon="${gmon}"
    done
    xrdb "${HOME}/.Xresources"
}

handle_args() {
    case "${1,,}" in
           "get") get_monitors
    ;;  "rotate") rotate_m "${@:2}"
    ;;         *) update_monitor_export
    ;; esac
}

handle_args "${@}"
