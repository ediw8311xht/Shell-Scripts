#!/bin/bash

#set -eu
# shellcheck disable=SC2155
script_main() ( #------------------ subshell begin ------------------------#
#-------UTILITY-FUNCTIONS-----#
  msg()                     { notify-send "${SCRIPT_NAME}$(printf "\n%s"  "${@}")"; }
  my_join()                 {  local IFS="${1}"; echo "${*:2}"; }
#----------------------------------------------------------#
#-------VARS-----------------------------------------------#
#----------------------------------------------------------#

#-------ZATHURA-DB-VARS-------#
  # Preference Order: plocate, fd, find
  local -r VALID_COMMAND_ARR=(plocate fd find)
  for i in "${VALID_COMMAND_ARR[@]}" ; do
    if command -v "${i}" >/dev/null ; then
      local -r FIND_COMMAND="${i}"
      break
    fi
  done
  # if command -v plocate ; then local -r 
  #local -r FIND_COMMAND="$(type -P plocate || type -P fd || type -P find)"
  local -r ZATHURA_DATA_DIR="${XDG_DATA_HOME:-"${HOME}/.local/share"}/zathura"
  local -r HFILE="${ZATHURA_DATA_DIR}/bookmarks.sqlite"
  local -r DMENU_SCRIPT="${HOME}/bin/my_dmenu.sh"
  if ! [[ -f "${DMENU_SCRIPT}" ]] ; then DMENU_SCRIPT="dmenu"; fi
  local -r SCRIPT_NAME="$(basename "${0}")"
#-------APP-INFO--------------#
  local -r APP_NAME='zathura'
  local -r APP_ORG='/org/pwmt/zathura'
  local -r APP_INT='org.pwmt.zathura'
#-------DATA------------------#
  local -r DATA_DIR="${XDG_DATA_HOME}/zathura_dbus_controller"
  local -r DATA_FILE="${DATA_DIR}/data.txt"
  local -r CACHE_DATABASE="${XDG_DATA_HOME}/plocate/home.db"
  local -r MOST_RECENT="${DATA_DIR}/most_recent.txt"
#-------DELIM-----------------#
  local -r DELIM=' :::: '
#-------ARRS------------------#
  local -r EXTS_ARR=( pdf epub azw2 djvu mobi )

#-------SCRIPT-VAR------------#
  local FILENAME=""
  local BUSLIST=()

#----------------------------------------------------------#
#-------FUNCTIONS------------------------------------------#
#----------------------------------------------------------#
  read_histfile() {
    while read -r -d $'\n' n ; do
      if [[ -f "${n}" ]] ; then
        printf '%s\n' "${n}"
      fi
    done < <(sqlite3 "${HFILE}" "SELECT file FROM fileinfo ORDER BY time" | tac)
  }
  make_data_dir()  { mkdir -p  "${DATA_DIR}" ; touch "${DATA_FILE}" ; touch "${MOST_RECENT}" ; }
  reset_data_dir() { trash-put "${DATA_DIR}" ; make_data_dir ; }
    # shellcheck disable=SC2295
  parse_busname()           { echo "${1#*${DELIM}}";  }
    # shellcheck disable=SC2295
  parse_filename()          { echo "${1%${DELIM}*}";  }
  in_buslist()              { printf '%s\0' "${BUSLIST[@]}" | grep -Fqzx "$(get_most_recent)"; }
#-------MOST-RECENT-----------#
  set_most_recent()         { echo "${1}" > "${MOST_RECENT}"; }
  get_most_recent()         { cat "${MOST_RECENT}"; }
  most_recent_filename()    { get_filename "$(get_most_recent)"; }
  check_most_recent() {
    if [[ "${#BUSLIST[@]}" -le 0 ]] ; then
      set_most_recent ""
    elif [[ "${1:-}" = "reset_recent" ]] || ! in_buslist "$(get_most_recent)" ; then
      set_most_recent "${BUSLIST[0]}"
    fi
  }
#-------DBUS------------------#
  get_user_bus_names()      { busctl --user --no-legend | awk -F ' ' '{ printf $1"\0" }'; }
  get_application_bus_names() { get_user_bus_names | grep -Fz "${APP_NAME}" | sort -zr; }
#-------SET-GET-CALL----------#
  get_dbus_property()       { busctl --user get-property "${1}" "${APP_ORG}" "${APP_INT}" "${2}" | grep -Pio '^[^ ]+[ ]*\K.+(?=[ ]*)$'; }
  call_dbus_method()        { busctl --user call         "${1}" "${APP_ORG}" "${APP_INT}" "${@:2}"; }
  get_filename()            { { get_dbus_property "${1}" "filename" | grep -Pio '(?<=^["]).*(?=["][ ]*$)'; } || echo "_"; }
  exec_command()            { busctl --user call "${1}" "${APP_ORG}" "${APP_INT}" "ExecuteCommand" s "${@:2}" ; }
  #set_dbus_property()       { busctl --user set-property "${1}" "${APP_ORG}" "${APP_INT}" "${2}" "${3}" "${4}"; }
#-------PAGE-NUMBER-----------#
  get_page_number()         { get_dbus_property "$(get_most_recent)" "pagenumber"; }
  set_page_number()         { call_dbus_method "$(get_most_recent)" "GotoPage" "u" "${1}"; }
  next_page()               { set_page_number "$(( "$(get_page_number)" + 1))"; }
  prev_page()               { set_page_number "$(( "$(get_page_number)" - 1))"; }
#-------COMMANDS--------------#
  toggle_recolor()          { exec_command "$(get_most_recent)" "set recolor" ; }
  open_file()               { exec_command "$(get_most_recent)" "open '${1}'" ; }
#-------DMENU-----------------#
  dmenu_get_filename()      { get_filenames | "${DMENU_SCRIPT}"; }
  update_database() {
    if updatedb -l 0 -U "${HOME}" -o "${CACHE_DATABASE}" ; then
      msg "Updated db" "${CACHE_DATABASE}"
    else
      msg "Error updating db"
    fi
  }
  find_t() {
    # shellcheck disable=SC2068
    case "${FIND_COMMAND}" in
             plocate) plocate -b --regex "[.]($(my_join "|" "${EXTS_ARR[@]}" ))$" -d "${CACHE_DATABASE}"
        ;;      find) # shellcheck disable=SC2046,SC2001
                      find "${HOME}" -hidden -iname $(sed 's/ / -o iname /g' <<< "${EXTS_ARR[*]}") "${HOME}" 2>/dev/null
        ;;         *) msg "Error" && exit 1
    esac
  }

  # plocate_ebooks() {
  #     local f
  #     while read -r -d $'\n'  f ;  do
  #       [[ ! -d "${f}" ]] && echo "${f}"
  #     done < <(plocate -b --regex "[.]($(my_join "|" "${EXTS_ARR[@]}" ))$" -d "${CACHE_DATABASE}")
  # }
  dmenu_open_file() {
    local my_file
    if [[ "${1:-}" = 'history' ]] ; then
      shift 1
      my_file="$(read_histfile | "${DMENU_SCRIPT}")"
    else
      my_file="$(find_t | "${DMENU_SCRIPT}")"
    fi

    if ! [[ -f "${my_file}" ]] ; then
      return 0
    elif [[ "${#BUSLIST[@]}" -le 0 ]] || [[ "${1:-}" = 'new' ]] ; then
      zathura --fork "${my_file}"
      sleep 2 #sketchy solution
      get_buslist
      check_most_recent "reset_recent"
    else
      open_file "${my_file}"
    fi
  }
#-----FILES-------------------------------------------#
  get_buslist()             { mapfile -d $'\0' BUSLIST < <(get_application_bus_names); }
  get_bus_by_filename() {
    if [[ "${FILENAME}" = "" ]] ; then cat "${MOST_RECENT}"
    else
      local data_line
      while read -r -d $'\n' data_line ; do
        if parse_filename "${data_line}" | grep -Fq "${FILENAME}" ; then
          parse_busname "${data_line}"
        fi
      done < "${DATA_FILE}"
    fi
  }
  set_data_files() {
    local f
    make_data_dir
    # reset data file
    echo "" > "${DATA_FILE}"
    for busname in "${BUSLIST[@]}" ; do
      f="$(get_filename "${busname}" 2>/dev/null)"
      echo "${f}${DELIM}${busname}" >> "${DATA_FILE}"
    done
  }
  get_filenames() {
    local data_line
    while read -r -d $'\n' data_line ; do
      parse_filename "${data_line}"
    done < "${DATA_FILE}"
  }
  find_in_file() {
    local f find
    f="$(most_recent_filename)"
    find="$(
      pdfgrep --max-count 1 --color "never" --perl-regexp --page-number "${*}" "${f}" \
        | grep -o "^[0-9]*" )"
    if [[ -n "${find}" ]] ; then
      set_page_number "${find}"
    fi
  }
#-----MAIN--------------------------------------------#
  main() {
    get_buslist
    check_most_recent
    set_data_files
    while [[ "${#}" -gt 0 ]] ; do
      case "${1}" in
          -g|--get)             check_most_recent "reset_recent" && msg "updated bus names" "$(get_most_recent)"
      ;;  -H|--history-new)     dmenu_open_file "history" "new"
      ;;  -O|--open-new)        dmenu_open_file "new"
      ;;  -U|--update-database) update_database
      ;;  -[0-9]*)              set_page_number "${1/-/}"
      ;;  -c|--current)         most_recent_filename
      ;;  -d|--set-dmenu)       FILENAME="$(dmenu_get_filename)"; set_most_recent "$(get_bus_by_filename)" && msg "set most recent" "$(get_most_recent)"
      ;;  -f|--files)           get_filenames
      ;;  -h|--history)         dmenu_open_file "history"
      ;;  -o|--open)            dmenu_open_file
      ;;  -p+|--nextpage)       next_page
      ;;  -p-|--prevpage)       prev_page
      ;;  -p|--pagenumber)      get_page_number
      ;;  -r|--recolor)         toggle_recolor
      ;;  -s|--set)             set_most_recent "$(get_bus_by_filename)"
      ;;  --pdfgrep)            find_in_file "${@:2}"
      ;;  --reset-data)         reset_data_dir && exit 0
      ;;  -*)                   echo "Invalid option"; return 1
      ;;   *)                   FILENAME="${1}"
      esac
      shift 1
    done
  }
  main "${@}"
  #echo "$FIND_COMMAND"
  # plocate -b --regex "[.]($(my_join "|" "${EXTS_ARR[@]}" ))$" -d "${CACHE_DATABASE}"
  # echo "[.]($(my_join "|" "${EXTS_ARR[@]}" ))$"
) #------------------ subshell end ------------------------#

script_main "${@}"

