#!/usr/bin/env bash


commitHash=''
nextHash=''
author=''
date=''
description=''
summary=''
coAuthors=()

us=$'\037'
OIFS=$IFS
RED='\033[01;31m'
GREEN='\033[01;32m'
YELLOW='\033[01;33m'
BLUE='\033[01;34m'
MAGEN='\033[01;35m'
CYAN='\033[01;36m'
WHITE='\033[01;37m'

function main {
  git log --pretty=format:"commitHash %h$us(%ar)$us%d$us%s$us%an$us%b" $@ |
  sed '/^[[:blank:]]*$/d' |
  parseGitLog |
  less -R
}

function parseGitLog { 
  IFS=$us
  while read data
  do 
    if [[ $data =~ (commitHash )(.*) ]]; then
      a=($data)
      nextHash=$( echo ${a[0]} | sed -e "s/commitHash \(.*\)/\1/" );
      if [[ $nextHash != $commitHash ]] && [[ $commitHash != '' ]]; then
        printCommit
      fi
      commitHash=$nextHash
      date=${a[1]}
      branch=${a[2]}
      summary=${a[3]}
      author=${a[4]}
      coAuthors=()
      possibleCoAuthor=${a[5]}
    else
      possibleCoAuthor=$data
    fi
    extractCoAuthor $possibleCoAuthor
  done

  printCommit
  IFS=$OIFS
}

function extractCoAuthor {
  if [[ $1 =~ (Co-authored-by: )(.*)( <.*) ]]; then
    authorFound=${BASH_REMATCH[2]}
    coAuthors+=($authorFound)
  fi
}

function printCommit {
  if [ ${#coAuthors[@]} -eq 0 ]; then
    coAuthors=""
  else
    CIFS=$IFS
    IFS=$OIFS
    coAuthors=$(join_by ', ' "${coAuthors[@]}")
    IFS=$CIFS
    coAuthors+=($author)

    for (( i=0; i<${#coAuthors[@]}; i++ ))
    do
       for (( j=i+1; j<${#coAuthors[@]}; j++ ))
        do
            echo "${coAuthors[$i]}","${coAuthors[$j]}"
        done
    done
#      echo "$author,${coAuthors[0]}"

  fi
#  echo "${CYAN}$commitHash ${YELLOW}$date ${WHITE}-${MAGEN}$branch ${WHITE}$summary ${BLUE}$author ${GREEN}$coAuthors"
}

#function join_by { local d=$1; shift; echo -n "$1"; shift; printf "%s" "${@/#/$d}"; }
function join_by { local IFS="$1"; shift; echo "$*"; }

main $@

