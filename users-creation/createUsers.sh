#!/bin/bash

check_input() {
  local inputFile="source.txt"

  while read line; do
    # Split the line into fields using the delimiter :
    IFS=':' read -ra fields <<< "$line"

    # Check that there are exactly 5 fields
    if [[ ${#fields[@]} -ne 5 ]]; then
      echo "Error: Incorrect number of fields in line: $line"
      return 1
    fi

    # Check that the 4th field (sudo) is either 'oui' or 'non'
    if [[ ${fields[3]} != 'oui' ]] && [[ ${fields[3]} != 'non' ]]; then
      echo "Error: Invalid value for sudo in line: $line"
      return 1
    fi

    # Check that the 5th field (password) is not empty
    if [[ -z ${fields[4]} ]]; then
      echo "Error: Password is empty in line: $line"
      return 1
    fi
  done < "$inputFile"
}

generate_login() {
  local firstName=$1
  local lastName=$2

  # Check if a user with the same first and last name already exists
  existing_user=$(grep -i "$firstName.*$lastName" /etc/passwd)
  if [ -n "$existing_user" ]; then
    return 1
  fi

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
  if [ "$sudo" == "oui" ]; then
    usermod -aG sudo $login
  fi
}

create_files() {
  local login=$1
  # Generate a random number between 5 and 10
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

  # Check the input file
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

    # Skip user creation if generate_login returns 1
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
    # The syntax ${variable//pattern/replacement} means "replace all occurrences of pattern in variable with replacement"
    # This is used to remove the primary group from the secondary groups
    local secondaryGroups=${groups//${primaryGroup},/}

    create_user $firstName $lastName $primaryGroup $secondaryGroups $login $password

    add_sudo $sudo $login

    create_files $login
  done < "$inputFile"
}

main
