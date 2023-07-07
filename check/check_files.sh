#!/bin/bash

find / -type f -executable -perm -4000 2> /dev/null > list_of_files.txt
find / -type f -executable -perm -2000  >> list_of_files.txt 2> /dev/null

new_file="list_of_files.txt"
old_file="last_list_of_files.txt"

declare -A files 
declare -A copy_files

while IFS= read -r file
do
	files["$file"]=1
	copy_files["$file"]=1

done < "$new_file"



if [ -f "$old_file" ]
then
	declare -A old_files
	while IFS= read -r file
	do

		old_files["$file"]=1
	done < "$old_file" 

	for file in ${!old_files[*]}
	do
		unset files["$file"]
	done

	for file in ${!copy_files[*]}
	do
		unset old_files["$file"]
	done


	if [ "${#files[*]}" -gt 0 ]
	then
		echo -e "\033[0;31mWARNING - DIFFERENCES FOUND:\033[0m "
		for file in "${!files[*]}"
		do
			 date=$(stat -c%y "$file")
			 echo "$date : $file"
		done
	fi

         if [ "${#old_files[*]}" -gt 0 ]
	then
		echo  -e "\033[0;31m WARNING - DIFFERENCES FOUND:\033[0m"
		for file in "${!old_files[*]}"
		do
			date=$(stat -c%y "$file")
			echo "$date : $file"
		done
	
	 fi

	 if [ "${#old_files[*]}" -eq 0 -o "${#files[*]}" -eq 0 ]
	 then
		echo -e  "\033[0;32mNo changes.\033[0m"
	 fi
		
fi
cp list_of_files.txt last_list_of_files.txt
