#!/usr/bin/bash

fzf_get() {
    local image_formats=(
        -e 'avif'
        -e 'gif'
        -e 'jpeg'
        -e 'jpg'
        -e 'png'
        -e 'webp'
    )
    fd -tf "${image_formats[@]}" . |  fzf
}

screenshot_with_maim() {
    timeout 30 maim --quality 10 --format="png" --hidecursor -s | tee "$HOME/.cache/screenshot_tmp/$(date '+%Y_%m_%_d__%Hh_%Mm_%Ss').png" | xclip -selection clipboard -target image/png
}

clipboard_copy_image() {
    local image_to_copy=""
    local file_type=""
    [[ "${#}" -le 0 ]] && {  echo "read the script dummy"; return 3; }
    case "${1,,}" in
         --fzf) image_to_copy="$(fzf_get "${@:2}")" || return 1
    ;;  --shot) screenshot_with_maim; return $?
    ;;       *) [[ -f "${1}" ]] || return 1
                image_to_copy="${1}"
    ;; esac
    file_type="$(mimetype -b "${image_to_copy}")" || {
        echo "${image_to_copy}, mimetype not found."
        exit 2
    }
    xclip -selection clipboard  \
          -t "${file_type}"     \
          < "${image_to_copy}"

}
clipboard_copy_image "${@}"
