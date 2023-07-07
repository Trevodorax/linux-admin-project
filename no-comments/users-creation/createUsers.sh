#!/bin/bash

check_input() {
  local inputFile="source.txt"

  while read line; do
 
    IFS=':' read -ra fields <<< "$line"

  
    if [[ ${#fields[@]} -ne 5 ]]; then
      echo "Error: Incorrect number of fields in line: $line"
      return 1
    fi

  
    if [[ ${fields[3]} != 'oui' ]] && [[ ${fields[3]} != 'non' ]]; then
      echo "Error: Invalid value for sudo in line: $line"
      return 1
    fi

    if [[ -z ${fields[4]} ]]; then
      echo "Error: Password is empty in line: $line"
      return 1
    fi
  done < "$inputFile"
}

generate_login() {
  local firstName=$1
  local lastName=$2

  
  existing_user=$(grep -i "$firstName.*$lastName" /etc/passwd)
  if [ -n "$existing_user" ]; then
    return 1
  fi

 
  local login=$(echo "${firstName:0:1}$lastName" | tr '[:upper:]' '[:lower:]')

 
  local counter=1

  while id -u $login >/dev/null 2>&1; do
    login=$(echo "${firstName:0:1}$lastName$counter" | tr '[:upper:]' '[:lower:]')
    counter=$((counter+1))
  done

  echo $login
}

create_groups() {
  local groups=$1
 
  IFS=',' read -ra groupArray <<< "$groups"

  for group in "${groupArray[@]}"; do
   
    if ! grep -q "^$group:" /etc/group; then
      groupadd $group
    fi
  done


  echo "${groupArray[@]}"
}

create_user() {
  local firstName=$1
  local lastName=$2
  local primaryGroup=$3
  local secondaryGroups=$4
  local login=$5
  local password=$6

  useradd -m -c "$firstName $lastName" -G "$secondaryGroups" -g "$primaryGroup" -p "$(openssl passwd -1 $password)" $login
  passwd --expire $login
  echo $login:$password
}

add_sudo() {
  local sudo=$1
  local login=$2
  if [ "$sudo" == "oui" ]; then
    usermod -aG sudo $login
  fi
}

create_files() {
  local login=$1

  local num_files=$(shuf -i 5-10 -n 1)
  local count=1

  while [ $count -le $num_files ]
  do
    dd >/dev/null 2>/dev/null if=/dev/zero of=/home/$login/file$count bs=1M count=$(shuf -i 5-50 -n 1) 
    ((count++))
  done
}

main() {
  local inputFile="source.txt"

  if ! check_input; then
    echo "Input file check failed, exiting."
    exit 1
  fi

  while read line; do
    local firstName=$(echo $line | cut -d: -f1)
    local lastName=$(echo $line | cut -d: -f2)
    local groups=$(echo $line | cut -d: -f3)
    local sudo=$(echo $line | cut -d: -f4)
    local password=$(echo $line | cut -d: -f5)


    if ! generate_login $firstName $lastName; then
      echo "Skipping user creation for $firstName $lastName"
      continue
    fi

    local login=$(generate_login $firstName $lastName)

    if [[ -z "$groups" ]]; then
      groups=$login
    fi
    local groupArray=($(create_groups $groups))

    local primaryGroup=${groupArray[0]}
    local secondaryGroups=${groups//${primaryGroup},/}

    create_user $firstName $lastName $primaryGroup $secondaryGroups $login $password

    add_sudo $sudo $login

    create_files $login
  done < "$inputFile"
}

main
