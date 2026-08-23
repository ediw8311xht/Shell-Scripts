#!/usr/bin/env bash

main() {
  local mark
  local keys
  local script_name="$(basename "${0}")"
  handle_args() {
    [[ "${#}" -le 0 ]] && return 0
    case "${1}" in
    -m | --mark)
      mark="${2}"
      shift 1
      ;;
    *)
      keys="${1}"
      ;;
    esac
    handle_args "${@:2}"
  }

  send_key() {
    local backwindow="$(xdotool getactivewindow)"
    if ! i3-msg "[con_mark=\"${mark}\"] focus" ; then
      notify-send -c "error" "${script_name}" "No window with mark '${mark}'"
      return 1
    fi
    xdotool key --clearmodifiers "${keys}" \
      windowactivate "${backwindow}" --delay 200
  }

  handle_args "${@}"

  if [[ -n "${mark}" ]] && [[ -n "${keys}" ]]; then
    send_key
  fi
}


main "${@}" &>> ~/.cache/i3wm_script.log

