#!/bin/bash

# Function to delete a user, including home directory and mail spool
delete_user() {
  local user=$1

  if id -u $user >/dev/null 2>&1; then
    userdel -r $user 2>/dev/null
    echo "Deleted user: $user"
  else
    echo "User $user does not exist"
  fi
}

# Function to delete users based on the original script logic
delete_users_from_input() {
  local inputFile="source.txt"

  while read line; do
    local firstName=$(echo $line | cut -d: -f1)
    local lastName=$(echo $line | cut -d: -f2)

    # tr allows us to bring everything to lowercase
    local login=$(echo "${firstName:0:1}$lastName" | tr '[:upper:]' '[:lower:]')

    # Delete the base user
    delete_user $login

    # Delete users with numbers appended
    local counter=1
    while id -u ${login}${counter} >/dev/null 2>&1; do
      delete_user "${login}${counter}"
      counter=$((counter+1))
    done
  done < "$inputFile"
}

delete_users_from_input
