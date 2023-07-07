#!/bin/bash

delete_user() {
  local user=$1

  if id -u $user >/dev/null 2>&1; then
    userdel -r $user 2>/dev/null
    echo "Deleted user: $user"
  else
    echo "User $user does not exist"
  fi
}

delete_users_from_input() {
  local inputFile="source.txt"

  while read line; do
    local firstName=$(echo $line | cut -d: -f1)
    local lastName=$(echo $line | cut -d: -f2)


    local login=$(echo "${firstName:0:1}$lastName" | tr '[:upper:]' '[:lower:]')

    delete_user $login

    local counter=1
    while id -u ${login}${counter} >/dev/null 2>&1; do
      delete_user "${login}${counter}"
      counter=$((counter+1))
    done
  done < "$inputFile"
}

delete_users_from_input
