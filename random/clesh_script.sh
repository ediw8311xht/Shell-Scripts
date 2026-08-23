#!/usr/bin/bash

__main() {
  local SCRIPT="/dev/stdin"
  local SCRIPT_ARGS=()
  local OPTS=(
    --noinform
    --load "$HOME/.sbclrc"
    --eval '(ql:quickload "asdf"  :silent t)'
    --eval '(ql:quickload "clesh" :silent t)'
  )
  local SETUP_QUICK=(
    --eval '(ql:quickload "named-readtables" :silent t)'
    --eval '(ql:quickload "uiop" :silent t)'
    --eval "(import 'clesh:script)"
    --eval "(import 'uiop:command-line-arguments)"
    --eval '(named-readtables:in-readtable clesh:syntax)'
  )
  __handle_args() {
    [[ -z "${1}" ]] && return
    case "${1}" in
    -s | --setup-quick)
      OPTS+=("${SETUP_QUICK[@]}")
      ;;
    -u | --import-utils)
      OPTS+=(--eval '(ql:quickload "maximilian-utils" :silent t)')
      ;;
    -h)
      declare -f "${FUNCNAME[0]}" | highlight --out-format 'truecolor' --syntax 'bash'
      return 1
      ;;
    --)
      SCRIPT="${*:2}"
      return 0
      ;;
    -*)
      echo "Unknown option" >&2
      return 2
      ;;
    *)
      SCRIPT="${1,,}"
      SCRIPT_ARGS=("${@:2}")
      return 0
      ;;
    esac
    __handle_args "${@:2}"
  }
  __handle_args "${@}" &&
    /usr/bin/sbcl "${OPTS[@]}" --script "${SCRIPT}" "${SCRIPT_ARGS[@]}"
}

__main "${@}"
