#!/usr/bin/env bash

i3wm_config_check() {

  local timeout_ask="3"
  local config_file="${XDG_CONFIG_HOME}/.i3/config"
  local error_output_file="${HOME}/.cache/i3_error.txt"
  local fg_font='xft:monospace 10'
  ask() {
    timeout "${1}" i3-input -f "${fg_font}" -l 1 -P 'SUCCESS RELOAD RESTART i3wm? (y/n)' |
      grep -Pi '(?<=^command = ).+$'
  }

  main() {
    if ! i3 -C "${config_file}" &>"${error_output_file}"; then
      nohup "${TERMINAL:-xterm}" -e "${EDITOR:-vim}" "${error_output_file}" &
      i3-input -f "${fg_font}" -l 1 -P '!![Error in your config file]!!'
      exit 1
    elif [[ "${o_NOASK:-"$(ask "${timeout_ask}")"}" =~ ^[^yY]*$ ]]; then
      timeout "${timeout_ask}" \
        i3-input -l 1 -f "${fg_font}" -P 'NOT Reloading/Restarting'
      exit 0
    fi

    i3-msg "reload; restart"

    if [[ "${timeout_ask}" -gt "0" ]]; then
      timeout "${timeout_ask}" \
        i3-input -l 1 -f "${fg_font}" -P 'Reloaded & Restarted'
    fi
  }

  handle_args() {
    while [[ "${1}" =~ ^- ]]; do
      if [[ "${1,,}" =~ ^--noask$ ]]; then
        o_NOASK="Y"
      elif [[ "${1,,}" =~ ^--[0-9]+$ ]]; then
        timeout_ask="${1:2}"
      elif [[ "${1}" =~ ^--c$ ]]; then
        config_file="${2}"
        shift 1
      else
        notify-send "${0}" "Invalid option '${1}'"
      fi
      shift 1
    done
  }
  #### FG_FONT='xft:monospace 15'

  handle_args "$@"
  main

}
i3wm_config_check "${@}"
