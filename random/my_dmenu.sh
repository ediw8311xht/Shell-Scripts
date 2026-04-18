#!/usr/bin/env bash


main() {
  set -eu
  # local DM_SETTINGS=()
  # read -r -d '' DM_SETTINGS < <(tr '\n' ' ' <<EOF
  # mapfile -d $'\n ' DM_SETTINGS < <(tr '\n' ' ' <<EOF
  local DM_SETTINGS="${XDG_CONFIG_HOME}/dmenu/dmenurc"
  # shellcheck source=/dev/null
  source "${DM_SETTINGS}"
  # provides DMENU_OPTIONS && DMENU_OPTIONS_G
	local DMENU_COMMAND='dmenu'
	local PROMPT=">"
    local i=0
    #local R_STDIN
    while [[ "${#}" -gt 0 ]] ; do
		case "${1,,}" in
                 -run) j4-dmenu-desktop --i3-ipc --dmenu="dmenu -p '${PROMPT}' ${DMENU_OPTIONS_G}" ; return 
        ;;   -run-def) DMENU_COMMAND="dmenu_run" ; shift 1
        ;;  -p|-prompt) PROMPT="${2}"; shift 2
        #;;  -i|--stdin) read -r -p -t 5 R_STDIN; shift 1
        #;;  *) R_STDIN="${*}"; break
        ;;  *) break
		;;  esac
    done
    #shellcheck disable=SC2046,SC2086
    # --kill after 
    timeout --kill-after=50 50 "${DMENU_COMMAND}" -p "${PROMPT}" ${DMENU_OPTIONS} \
        < <( sed -e "s|$HOME|~|" /dev/stdin) \
        | sed "s|\~|$HOME|"
}

main "${@}"

