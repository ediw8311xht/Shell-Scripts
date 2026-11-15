#!/usr/bin/bash
# shellcheck disable=SC2164
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
    fd -tf "${image_formats[@]}" . | fzf
  }

  _screenshot_with_maim() {
    if [[ "${1}" = 'save' ]]; then
      local dir="${MARKDOWN_IMAGES:-"${HOME}/.local/share/markdown-images/"}"
      cd "${dir}" || return 1

      local file_name="$(my_dmenu.sh -prompt "enter filename > " -input < <(fd -tf -e png --format "{.}" ))"

      [[ -n "${file_name}" ]] || return 1

      local output_file="${dir}/${file_name}.png"

      if timeout 30 maim --quality 10 --format="png" --hidecursor -s >"${output_file}"; then
        xclip -selection clipbaord <<<"${output_file}"
      fi
    else
      timeout 30 maim --quality 10 --format="png" --hidecursor -s |
        tee "$HOME/.cache/screenshot_tmp/$(date '+%Y_%m_%_d__%Hh_%Mm_%Ss').png" |
        xclip -selection clipboard -target image/png
    fi
  }

  _main() {
    local image_to_copy=""
    local file_type=""

    [[ "${#}" -le 0 ]] && {
      declare -f _main
      return 3
    }
    case "${1,,}" in
    --save)
      _screenshot_with_maim "save"
      return $?
      ;;
    --fzf) image_to_copy="$(_fzf_get "${@:2}")" || return 1 ;;
    --shot)
      _screenshot_with_maim
      return $?
      ;;
    *)
      [[ -f "${1}" ]] || return 1
      image_to_copy="${1}"
      ;;
    esac

    if file_type="$(mimetype -b "${image_to_copy}")" ; then
      xclip -selection clipboard -t "${file_type}" <"${image_to_copy}"
    else
      echo "${image_to_copy}, mimetype not found."
      return 2
    fi
  }

  pushd -n "${PWD}"
  trap 'popd &>/dev/null' 0
  _main "${@}"
}
_clipboard_copy_image "${@}"
