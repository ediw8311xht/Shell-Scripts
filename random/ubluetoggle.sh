#!/usr/bin/env bash

main() {
  # shellcheck disable=SC2034
  local SCRIPT_NAME="${0##*/}"
  # local LOGS_DIR="${XDG_DATA_HOME}/script_logs/"
  local NOTIFY_ICON="${HOME}/bin/Resources/Images/bluetooth.png"
  local DEVMAC=""
  local TIMEOUT="5"
  local pid
  # will use this later... maybe
  # bluetooth on
  __notify() { notify-send -a "${SCRIPT_NAME}" "${@}"; }

  __send_m() {
    if [[ "${1}" -eq 0 ]]; then
      __notify -c "success" "Success: ${2}"
    else __notify -c "error" "Error: ${2}"; fi
  }

  __connect() {
    bluetoothctl --timeout "${TIMEOUT}" \
      <<< "power on"
    sleep 1
    bluetoothctl --timeout "${TIMEOUT}" \
      <<< $'\n'"connect '${DEVMAC}'"
    # & pid=$!
    __send_m $? "connected"
  }
  __disconnect() {
    bluetoothctl power off
    __send_m $? "disconnected"
  }

  __ubluetoggle() {
    if ! bluetoothctl info; then
      __connect
    else __disconnect; fi
  }

  if ! systemctl --quiet is-active bluetooth; then
    __send_m "ubluetoggle.sh" "Bluetooth not enabled"
    return 1
  fi
  __ubluetoggle
}
main "${@}"
