#!/usr/bin/env bash

####################
( #-START-SUBSHELL-#
####################

command -v dunst && DUNST_INSTALLED=1
L_DIRS=()
L_PICS=()
SILENT='0'
DATA_FILE="$HOME/bin/Data/xwallautoDATA.txt"
MY_DMENU="${DMENU_SCRIPT:-dmenu}"
IS_DM=''
MAIN_DIR=''
DPOS=''
PICPOS=''
PARGS=''

my_printer() {
  printf "%3d\t%s" "${@}"
}

notify_wallpaper_change() {
  local string
  # -- Uncomment this if you want to close already open notification --
  if [[ -n "${DUNST_INSTALLED}" ]] ; then
    dunstctl close-all
  fi
  string=(
    "feh ${PARGS[*]:---bg-fill}"
    "$(my_printer "${DPOS}"  "$(basename "${L_DIRS[DPOS]}")")"
    "$(my_printer "${PICPOS}"  "${L_PICS[${PICPOS}]##*/}")"
  )

  if [[ -n "${DUNST_INSTALLED}" ]] ; then
    dunstify --appname="Wallpaper Script" -- "${string[0]}" "$(printf '%s\n' "${string[@]:1}")"
  else
    notify-send --appname="Wallpaper Script" "${string[0]}" "$(printf '%s\n' "${string[@]: 1}")"
  fi
}

init_data_file() {
  touch "${DATA_FILE}"
  if [[ "$(wc -l <"${DATA_FILE}")" -lt 4 ]] ; then
    echo $'\n\n\n\n\n\n\n' > "${DATA_FILE}" # IF DATA FILE IS EMPTY THEN ADD LINES
  fi
}

#-------------RESERVE-FIRST-LINE--#
read_from_data_file() {
  MAIN_DIR="$(    sed -n 2p "${DATA_FILE}"   )"
  DPOS="$(        sed -n 3p "${DATA_FILE}"   )"
  PICPOS="$(      sed -n 4p "${DATA_FILE}"   )"
  PARGS="$(       sed -n 5p "${DATA_FILE}"   )"
  [[             -d "${MAIN_DIR}" ]] || MAIN_DIR="$HOME/Pictures/Wallpapers"
  [[   "${DPOS}" =~ ^[1-9][0-9]*$ ]] || DPOS=0
  [[ "${PICPOS}" =~ ^[1-9][0-9]*$ ]] || PICPOS=0
}

update_data_file() {
  sed -i '2s#.*#'"${MAIN_DIR}"'#'  "${DATA_FILE}"
  sed -i '3s#.*#'"${DPOS}"'#'      "${DATA_FILE}"
  sed -i '4s#.*#'"${PICPOS}"'#'    "${DATA_FILE}"
  sed -i '5s#.*#'"${PARGS[*]}"'#'   "${DATA_FILE}"
}

pic_find() {
  fd . -a --exact-depth 1 -e 'jpg' -e 'jpeg' -e 'webp' -e 'png' --format '{}' "${1}" | sort -u
}

dirs_with_pics() {
  fd  . --exact-depth 1 -td  --absolute-path "${MAIN_DIR}" | sort -u
}

dmenu_set() {
  local a
  a="$(fd . -tf -e 'jpg' -e 'webp' -e 'png' -e 'jpg' "${MAIN_DIR}" | "${MY_DMENU}")" && \
    feh "${PARGS[@]:---bg-fill}" "${a}"
}

handle_args() {
  case "${1,,}" in
        dmenu) IS_DM=1
  ;;     left) PICPOS=0 ; ((DPOS--))
  ;;    right) PICPOS=0 ; ((DPOS++))
  ;;       up) ((PICPOS++))
  ;;     down) ((PICPOS--))
  ;; --silent) SILENT=1
  ;;  --pargs) PARGS=( "${2}" ); shift 1
  ;; esac
  shift 1
  [[ "$#" -ge 1 ]] && handle_args "${@}"
}

main() {
  init_data_file
  read_from_data_file
  handle_args "${@}"

  if [[ -n "${IS_DM}" ]] ; then
    dmenu_set
    return $?
  fi

  mapfile -t "L_DIRS" < <(dirs_with_pics)
  [[ "$(( DPOS %= "${#L_DIRS[@]}" ))" -ge 0 ]] || (( DPOS += "${#L_DIRS[@]}" ))

  mapfile -t "L_PICS" < <(pic_find "${L_DIRS[ "${DPOS}" ]}")
  [[ "$(( PICPOS %= "${#L_PICS[@]}" ))" -ge 0 ]] || (( PICPOS += "${#L_PICS[@]}" ))

  #-----CHANGE-WALLPAPER---------------------------------------------------------#
  feh "${PARGS[@]:---bg-fill}" "${L_PICS[ "${PICPOS}" ]}"
  #-----UPDATE-DATA-FILE---------------------------------------------------------#
  update_data_file
  #-----NOTIFICATION-------------------------------------------------------------#
  if [[ "${SILENT}" -eq 0 ]] ; then
    notify_wallpaper_change
  fi
}

main "${@}"
####################
) #---END-SUBSHELL-#
####################

