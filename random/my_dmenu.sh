#!/usr/bin/env bash


main() {
  # local DM_SETTINGS=()
  # read -r -d '' DM_SETTINGS < <(tr '\n' ' ' <<EOF
  # mapfile -d $'\n ' DM_SETTINGS < <(tr '\n' ' ' <<EOF
  local DM_SETTINGS="${XDG_CONFIG_HOME}/dmenu/dmenurc" # exports DMENU_OPTIONS and DMENU_OPTIONS_G
  # shellcheck source=/dev/null
  source "${DM_SETTINGS}"
  # provides DMENU_OPTIONS && DMENU_OPTIONS_G
	local DMENU_COMMAND='dmenu'
	local PROMPT=">"
  local RUN_WITH_SELECTION
  local LEFT_OVER_ARGS=()
  __j4_run () {
    j4-dmenu-desktop --i3-ipc --dmenu="dmenu -p '${PROMPT}' ${DMENU_OPTIONS_G}"
  }
  __dm_run () {
    # shellcheck disable=SC2086
    timeout --kill-after=50 50 "${DMENU_COMMAND}" -p "${PROMPT}" ${DMENU_OPTIONS} \
      < <( sed -e "s|$HOME|~|" /dev/stdin) \
      | sed "s|\~|$HOME|"
  }
  __handle_args() {
    while [[ "${#}" -gt 0 ]] ; do
      case "${1,,}" in
                         -run) DMENU_COMMAND="j4"
      ;;             -run-def) DMENU_COMMAND="dmenu_run"
      ;;   --run-with-command) RUN_WITH_SELECTION="${2}"       ; shift 1
      ;;     --run-with-xargs) RUN_WITH_SELECTION="xargs ${2}" ; shift 1
      ;;           -p|-prompt) PROMPT="${2}" ; shift 1
      ;;            -h|--help) declare -f "${FUNCNAME[0]}"; exit 0
      ;;                    *) LEFT_OVER_ARGS+=("${1}")
      ;;  esac
      shift 1
    done
  }
  #shellcheck disable=SC2046,SC2086
  # --kill after
  # [[ -n "${RUN_WITH_SELECTION}" && "${DMENU_COMMAND}" != "dmenu" ]] && echo "Run with selection ignored for non"
  __handle_args "${@}"
  if [[ "${DMENU_COMMAND}" = "j4" ]] ; then
    __j4_run "${LEFT_OVER_ARGS[@]}"
  else
    __dm_run "${@}" | ${RUN_WITH_SELECTION:-xargs echo}
  fi

}

main "${@}"

