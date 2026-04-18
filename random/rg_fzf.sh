#!/usr/bin/env bash

rg_fzf_func() {

    local RG_PREFIX="rg --no-config --no-search-zip --column --line-number --no-heading --color=always --smart-case"
    if [[ "${1}" =~ [-][u]{1,3} ]] ; then RG_PREFIX+=" ${1}"; shift 1; fi
    local -r lf_script="${HOME}/bin/cd_from_lf.sh"
    local outarr
    local dir
    local file
    local -r INITIAL_QUERY="${*:-}"
    local -r OPTIONS=(
        --ansi --disabled --query "$INITIAL_QUERY"
        --bind "start:reload:$RG_PREFIX {q}"
        --bind "change:reload:sleep 0.1; $RG_PREFIX {q} || true"
        --bind "ctrl-b:become(  printf '%s\0' 'browser' {1}     )"
        --bind "ctrl-l:become(  printf '%s\0' 'lf'      {1}     )"
        --bind "ctrl-x:execute( printf '%s\0' 'xdg'     {1}     )"
        --bind "ctrl-c:become(  printf '%s\0' 'cd'      {1}     )"
        --bind "enter:become(   printf '%s\0' 'edit'    {1} {2} )"
        --bind "ctrl-t:toggle-preview"
        --bind "ctrl-d:half-page-down"
        --bind "ctrl-u:half-page-up"
        --bind "ctrl-g:preview-half-page-down"
        --bind "ctrl-h:preview-half-page-up"
        --delimiter :
        --preview 'bat --color=always {1} --highlight-line {2}'
        --preview-window 'right,50%,border-bottom,+{2}+3/3,~3'
    )
    if mapfile -d $'\0' outarr < <(fzf "${OPTIONS[@]}") ; then
        dir="$(dirname "${outarr[1]}")"
        file="$(basename "${outarr[1]}")"
        cd "${dir}" || { echo "Couldnt cd to '${dir}'"; exit 1; }
        case "${outarr[0]}" in
                 lf) "${lf_script}" "${file}"
        ;;  browser) "${BROWSER}" "${file}"
        ;;      xdg) xdg-open "${file}"
        ;;     edit) "${EDITOR}" "${file}" +"${outarr[2]}"
        ;; esac
    fi
    # hi
}


rg_fzf_func "${@}"
