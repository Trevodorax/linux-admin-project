#!/bin/bash

#FIND FILES : -perm for permissions and we want suid and sgid then
echo "# EXECUTABLE FILES WITH SUID OR SGID RIGHTS" > list_of_files.txt 
find / -type f -executable -perm -4000 >> list_of_files.txt 2> /dev/null
find / -type f -executable -perm -2000  >> list_of_files.txt 2> /dev/nulli


#KEEP THE FILE FOR NEXT LAUNCH
cp list_of_files.txt last_list_of_files.txt
