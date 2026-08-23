#!/usr/bin/env bash

# shellcheck disable=SC2016,SC2153
# line 27 - for hint variable in quotes

refresh_main() {
  local script_name="${0##*/}"
  local sendkey="ctrl+r"
  local notify=false
  local browser="${BROWSER##*/}"
  local backwindow

  script_notify() {
    local category="script.status"
    if [[ "${*,,}" = 'error' ]]; then
      local category="script.error"
    fi

    if [[ "${notify}" = true ]]; then
      notify-send "${script_name}" "${*}"
    else
      if [[ "${category}" =~ "error" ]]; then
        echo "${*}" >&2
      else
        echo "${*}"
      fi
    fi
  }

  handle_args() {
    while [[ -n "${1}" ]]; do
      case "${1,,}" in
      -n | --notify)
        notify=true
        ;;
      -h | --hard)
        sendkey='ctrl+shift+r'
        ;;
      -*)
        script_notify "invalid option" && exit 1
        ;;
      *)
        browser="${1}"
        ;;
      esac
      shift 1
    done
  }

  xdotool_com() {
    xdotool search --onlyvisible --name "${browser}" \
      windowactivate --sync key --clearmodifiers --delay 100 "${sendkey}" &&
      xdotool windowactivate "${backwindow}"
  }

  main() {
    handle_args "${@}"
    backwindow="$(xdotool getactivewindow)"
    if [[ -n "${browser}" ]]; then
      if xdotool_com; then
        script_notify "Refreshed"
      else
        script_notify "Error"
      fi
    else
      script_notify 'Error: $BROWSER needs to be set or passed as argument.'
    fi
  }
  main "${@}"
}
refresh_main "${@}"
