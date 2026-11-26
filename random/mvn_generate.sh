#!/usr/bin/env bash

_generate_mvn_project() {
  local MVN_TYPE=mvn
  local ARGS=(
  )
  local MVN_DIR="${CODING}/JAVA/Maven"

  _update_versions() {
    ${MVN_TYPE} versions:use-latest-releases
  }
  _setup() {
    export JAVA_HOME='/usr/lib/jvm/java-25-openjdk/'

    local ARTIFACT_ID="${1}"
    local GROUP_ID="${2:-"com.maxballard.java"}"

    # if [[ ! -d "${MVN_DIR}" ]] || ! cd "${MVN_DIR}"; then
    #   echo "Couldn't cd into directory: '${MVN_DIR}'" >&2
    #   return 1
    # fi
    local settings=(
      archetypeGroupId=com.maxballard.java
      archetypeArtifactId=maximilian-template-archetype
      archetypeVersion=1.0-SNAPSHOT
      artifactId="${ARTIFACT_ID}"
      groupId="${GROUP_ID}"
      version=1.0.0
      interactiveMode=false
    )
    ${MVN_TYPE} archetype:generate "${settings[@]/#/-D}"
  }

  _spring() {
    # maybe i will add this later idk
    # local PID_FILE="${PWD}/.java_pid"
    # case "${1,,}" in
    # stop)
    #   killall <<< <(
    #   return
    #   ;;
    # restart) killall ;;
    # run) ;;
    # *) ;;
    # esac
    case "${1,,:-"n"}" in
    v) ${MVN_TYPE} "${ARGS[@]}" versions:use-latest-releases ;;
    *) ${MVN_TYPE} "${ARGS[@]}" spring-boot:run "${@}" ;;
    esac
  }

  _handle_args() {
    while [[ "${#}" -gt 0 ]]; do
      case "${1,,}" in
      c | clean) ARGS+=(clean) ;;
      m | mvnw) MVN_TYPE='./mvnw' ;;& # catch spring but also allow explicit with `-w` SWAG!
      x | exec) ${MVN_TYPE} "${ARGS[@]}" compile exec:java ;;
      i | install) ${MVN_TYPE} "${ARGS[@]}" clean install ;;
      sp | spring)
        MVN_TYPE="./mvnw"
        _spring "${@:2}"
        return
        ;;
      se | setup)
        _setup "${@:2}"
        return
        ;;
      *) return ;; esac
      shift 1
    done
  }

  _handle_args "${@}"
}
#
_generate_mvn_project "${@}"
# ./n.sh
# ./mvnw spring-boot:run
