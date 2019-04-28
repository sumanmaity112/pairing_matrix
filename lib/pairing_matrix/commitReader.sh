#!/usr/bin/env bash

COMMIT_HASH=''
NEXT_HASH=''
AUTHOR=''
CO_AUTHORS=()

US=$'\037'
OIFS=$IFS

function __extractCoAuthor(){
  if [[ $1 =~ (Co-authored-by: )(.*)( <.*) ]]; then
    CO_AUTHORS+=(${BASH_REMATCH[2]})
  fi
}

function __printPairs() {
    for (( i=0; i<${#CO_AUTHORS[@]}; i++ ))
    do
       for (( j=i+1; j<${#CO_AUTHORS[@]}; j++ ))
        do
            echo "${CO_AUTHORS[$i]}","${CO_AUTHORS[$j]}"
        done
    done
}

function __joinBy() {
 local IFS="$1"; shift; echo "$*";
}

function __printCommit() {
   if [[ -n ${CO_AUTHORS} ]]; then
        CO_AUTHORS=$(__joinBy ', ' "${CO_AUTHORS[@]}")
        CO_AUTHORS+=(${AUTHOR})
        __printPairs
   fi
}

function __parseGitLog() {
  IFS=${US}
  while read STREAM_DATA
  do
    local POSSIBLE_CO_AUTHOR=${STREAM_DATA}
    if [[ ${STREAM_DATA} =~ (commitHash )(.*) ]]; then
      local DETAILS=(${STREAM_DATA})
      NEXT_HASH=$( echo ${DETAILS[0]} | sed -e "s/commitHash \(.*\)/\1/" );
      if [[ ${NEXT_HASH} != ${COMMIT_HASH} ]] && [[ ${COMMIT_HASH} != '' ]]; then
        __printCommit
      fi
      COMMIT_HASH=${NEXT_HASH}
      AUTHOR=${DETAILS[1]}
      CO_AUTHORS=()
      POSSIBLE_CO_AUTHOR=${DETAILS[2]}
    fi
    __extractCoAuthor ${POSSIBLE_CO_AUTHOR}
  done

  __printCommit
  IFS=${OIFS}
}

function main() {
  git log --pretty=format:"commitHash %h$US%an$US%b" $@ |
  sed '/^[[:blank:]]*$/d' | __parseGitLog
}

main $@

