#!/usr/bin/bash


_clipboard_copy_image() {
  _fzf_get() {
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

  _screenshot_with_maim() {
    if [[ "${1}" = 'save' ]] ; then
      local file_name="$(my_dmenu.sh -prompt "enter filename > " -input)"
      if [[ -z "${file_name}" ]] ; then return 1 ; fi
      local output_file="${MARKDOWN_IMAGES:-"${HOME}/.local/share/markdown-images/"}/${file_name}.png"
      if timeout 30 maim --quality 10 --format="png" --hidecursor -s >  "${output_file}" ; then
        xclip -selection clipbaord <<< "${output_file}"
        echo "${output_file}"
      fi
    else
      timeout 30 maim --quality 10 --format="png" --hidecursor -s | tee "$HOME/.cache/screenshot_tmp/$(date '+%Y_%m_%_d__%Hh_%Mm_%Ss').png" | xclip -selection clipboard -target image/png
    fi
  }

  _main() {
      local image_to_copy=""
      local file_type=""

      [[ "${#}" -le 0 ]] && {  declare -f _main; return 3; }
      case "${1,,}" in
          --save) _screenshot_with_maim "save"; return $?
      ;;   --fzf) image_to_copy="$(_fzf_get "${@:2}")" || return 1
      ;;  --shot) _screenshot_with_maim; return $?
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
  _main "${@}"
}
_clipboard_copy_image "${@}"
