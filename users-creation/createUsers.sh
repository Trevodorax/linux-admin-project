#!/bin/bash

generate_login() {
  local firstName=$1
  local lastName=$2

  # tr allows us to bring everything to lowercase
  local login=$(echo "${firstName:0:1}$lastName" | tr '[:upper:]' '[:lower:]')

  # This loop keeps increasing the number in the login as long as the user name is already taken
  local counter=1
  # id -u $login returns the id of the user with login == $login
  while id -u $login >/dev/null 2>&1; do
    login=$(echo "${firstName:0:1}$lastName$counter" | tr '[:upper:]' '[:lower:]')
    counter=$((counter+1))
  done

  echo $login
}

create_groups() {
  local groups=$1
  # IFS = Internal Field Separator (character used to split strings)
  # -ra : (R)ead into (A)rray
  # Create an array of groups
  IFS=',' read -ra groupArray <<< "$groups"


  for group in "${groupArray[@]}"; do
    # -q for (Q)uiet
    if ! grep -q "^$group:" /etc/group; then
      groupadd $group
    fi
  done

  # array[@] returns all the elements in the array
  echo "${groupArray[@]}"
}

create_user() {
  local firstName=$1
  local lastName=$2
  local primaryGroup=$3
  local secondaryGroups=$4
  local login=$5
  local password=$6

  # "$(openssl passwd -1 $password)" because useradd wants a hashed password
  useradd -m -c "$firstName $lastName" -G "$secondaryGroups" -g "$primaryGroup" -p "$(openssl passwd -1 $password)" $login
  passwd --expire $login
  echo $login:$password
}

add_sudo() {
  local sudo=$1
  local login=$2
  if [ "$sudo" == "yes" ]; then
    usermod -aG sudo $login
  fi
}

create_files() {
  local login=$1
  # loops 5 to 10 times (-n means return only one line, so only one number)
  for i in {1..$(shuf -i 5-10 -n 1)}; do

    truncate -s $(shuf -i 5-50 -n 1)M /home/$login/file$i
  done
}

main() {
  local inputFile="source.txt"
  while read line; do
    local firstName=$(echo $line | cut -d: -f1)
    local lastName=$(echo $line | cut -d: -f2)
    local groups=$(echo $line | cut -d: -f3)
    local sudo=$(echo $line | cut -d: -f4)
    local password=$(echo $line | cut -d: -f5)

    local login=$(generate_login $firstName $lastName)

    if [[ -z "$groups" ]]; then
      groups=$login
    fi
    local groupArray=($(create_groups $groups))

    local primaryGroup=${groupArray[0]}
    # The syntax ${variable//pattern/replacement} means "replace all occurrences of pattern in variable with replacement".
    # This is used to remove the primary group from the secondary groups
    local secondaryGroups=${groups//${primaryGroup},/}

    create_user $firstName $lastName $primaryGroup $secondaryGroups $login $password

    add_sudo $sudo $login

    create_files $login
  done < "$inputFile"
}

main
