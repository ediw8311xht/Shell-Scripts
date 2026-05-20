#!/bin/bash

set -eu
main() {
  local DMENU_SCRIPT="${HOME}/bin/my_dmenu.sh"
  local DIR_I3="${HOME}/.config/i3/"
  local DIR_I3_BORDER='borders/'
  local DIR_I3_COMP="${DIR_I3}/${DIR_I3_BORDER}/"
  local XREC_FILE="${HOME}/.Xresources"
  local XREC_VAR='i3wm.BORDER_FILE'

  __write_xrec() {
    echo "${1}"
    if grep -qF "${XREC_VAR}:" "${XREC_FILE}"; then
      sed -i -E "s#^(${XREC_VAR}:).*#\1 ${DIR_I3_BORDER}${1}#" "${XREC_FILE}"
    else
      echo "${XREC_VAR} not defined in ${XREC_FILE}"
      exit 1
    fi
  }

  __swap_border() {
    local border_file
    if [[ -d "${DIR_I3_COMP}" ]]; then
      border_file="$(find "${DIR_I3_COMP}" -type f -iname "border*" -printf '%f\n' | "${DMENU_SCRIPT}")"
      if [[ -f "${DIR_I3_COMP}/${border_file}" ]]; then
        __write_xrec "${border_file}"
      fi
    else
      echo "ERROR IN SWAP BORDER:"
      echo -e "\t ${!DIR_I3*}"
      echo -e "\t'${DIR_I3}', '${DIR_I3_BORDER}', or '${DIR_I3_COMP}'"
      exit 1
    fi
  }

  __swap_border
  xrdb "${XREC_FILE}"
  i3 -C "${DIR_I3}/config/"
  i3-msg "reload; restart"
}

main "${@}"
