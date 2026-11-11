#!/usr/bin/bash

_generate_mvn_project() {
  _setup() {
    export JAVA_HOME='/usr/lib/jvm/java-25-openjdk/'

    local ARTIFACT_ID="${1}"
    local GROUP_ID="${2:-"com.maxballard.java"}"

    cd "${CODING}/JAVA/Maven" || {
      echo "dir not found"
      return 1
    }
    local settings=(
      archetypeGroupId=com.maxballard.java
      archetypeArtifactId=maximilian-template-archetype
      archetypeVersion=1.0-SNAPSHOT
      artifactId="${ARTIFACT_ID}"
      groupId="${GROUP_ID}"
      version=1.0.0
      interactiveMode=false
    )
    mvn archetype:generate "${settings[@]/#/-D}"
  }

  _main() {
    if [[ -z "${1}" ]]; then
      echo "Must provide artifactId"
      return 1
    elif [[ "${1}" = '-r' ]]; then
      mvn clean compile exec:java
      return 0
    elif [[ "${1}" = '-i' ]]; then
      # `mvn clean install` to install to ~/.mvn
      mvn clean install
    else
      _setup "${@}"
    fi
  }

  _main "${@}"
}

_generate_mvn_project "${@}"
