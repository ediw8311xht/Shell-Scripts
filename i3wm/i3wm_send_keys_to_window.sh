#!/usr/bin/env bash

main() {
  local mark
  local keys
  local delay=0.15
  local script_name="$(basename "${0}")"
  handle_args() {
    [[ "${#}" -le 0 ]] && return 0
    case "${1}" in
    -d | --delay)
      delay="${2}" # in seconds
      shift 1
      ;;
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
    sleep "${delay}"
    if ! i3-msg "[con_mark=\"${mark}\"] focus"; then
      notify-send -c "error" "${script_name}" "No window with mark '${mark}'"
      return 1
    fi
    xdotool key --clearmodifiers --delay 200 "${keys}" \
      windowactivate --sync "${backwindow}"
  }

  handle_args "${@}"

  if [[ -n "${mark}" ]] && [[ -n "${keys}" ]]; then
    send_key
  fi
}

main "${@}" |& tee -a ~/.cache/i3wm_script.log
