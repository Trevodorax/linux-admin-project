#!/bin/bash

#FIND FILES : -perm for permissions and we want suid and sgid then
echo "# EXECUTABLE FILES WITH SUID OR SGID RIGHTS" > list_of_files.txt 
find / -type f -executable -perm -4000 >> list_of_files.txt 2> /dev/null
find / -type f -executable -perm -2000  >> list_of_files.txt 2> /dev/null

file="list_of_files.txt"
old_file="last_list_of_files.txt"

#CHECK DIFF BETWEEN OLD AND NEW FILES
# -f = normal file -s = exist and not empty

if [ -f $file -a -f $old_file ]
then
	diff=$(diff $file $old_file | grep -E "^< " | cut -d' ' -f2)
	if [ -n "$diff" ]	
	then
		echo -e "\e[31m WARNING: DIFFERENCES FOUND ON :\e[0m"
		echo $diff
		last_line=""
		while IFS= read -r modified_file; do
			#GET THE FILE LAST MODIFICATION DATE WITH FORMAT DATE
			if [ -f $modified_file ]
			then

				if [ $last_file != $modified_file ]
				then
					date=$(stat -c%y $modified_file)
					echo "$modified_file modified on : $date"
				fi
			fi
			last_file=$modified_file
		done <<< $diff	
	else 
		echo -e "\033[0;32mNo changes since last launch of the script !\033[0m"
		echo "Check $file."
	fi
fi

#KEEP THE FILE FOR NEXT LAUNCH
cp $file $old_file

#echo -e "\e[31mTEST TEST TEST\e[0m"
