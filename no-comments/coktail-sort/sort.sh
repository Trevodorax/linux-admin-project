#!/bin/bash

convert_size() {
    local size=$1
    local -i gb=0 mb=0 kb=0

    if (( size >= 1024**3 )); then
        gb=$((size / 1024**3))
        size=$((size % 1024**3))
    fi

    if (( size >= 1024**2 )); then
        mb=$((size / 1024**2))
        size=$((size % 1024**2))
    fi

    if (( size >= 1024 )); then
        kb=$((size / 1024))
        size=$((size % 1024))
    fi

    echo "${gb}Go,${mb}Mo,${kb}Ko et ${size}octets"
}

calculate_size() {
    local user=$1
    local size=$(du -s "$(eval echo ~"$user")" 2>/dev/null | awk '{print $1}')
    echo "$size"
}


users=$(getent passwd | awk -F: '$3 >= 1000 {print $1}')

declare -A sizes


for user in $users; do
    size=$(calculate_size "$user")
    sizes["$user"]=$size
done

sorted_users=("${!sizes[@]}")
n=${#sorted_users[@]}
sorted=1

while (( sorted == 1 )); do
    sorted=0

    for (( i=0; i<n-1; i++ )); do
        current_user=${sorted_users[$i]}
        next_user=${sorted_users[$((i+1))]}

        if (( sizes["$current_user"] < sizes["$next_user"] )); then
      
            sorted_users[$i]=$next_user
            sorted_users[$((i+1))]=$current_user
            sorted=1
        fi
    done

    (( n-- ))

    if (( sorted == 0 )); then
        break
    fi

    for (( i=n-1; i>0; i-- )); do
        current_user=${sorted_users[$i]}
        prev_user=${sorted_users[$((i-1))]}

        if (( sizes["$current_user"] > sizes["$prev_user"] )); then
        
            sorted_users[$i]=$prev_user
            sorted_users[$((i-1))]=$current_user
            sorted=1
        fi
    done
done

echo "Liste des 5 plus gros consommateurs d'espace :"

for (( i=0; i<5 && i<5; i++ )); do
    user=${sorted_users[$i]}
    size=${sizes["$user"]}
    converted_size=$(convert_size "$size")
    echo "$user : $converted_size"
done

for user in $users; do
    user_home="$(eval echo ~"$user")"
    bashrc_file="$user_home/.bashrc"

    if [[ -f "$bashrc_file" ]]; then
        if ! grep -q "taille du répertoire personnel" "$bashrc_file"; then
	
   	    echo "" >> "$bashrc_file"
   	    echo "# Fonction pour convertir la taille en Go, Mo, Ko et octets" >> "$bashrc_file"
   	    echo "convert_size() {" >> "$bashrc_file"
   	    echo "    local size=\$1" >> "$bashrc_file"
   	    echo "    local -i gb=0 mb=0 kb=0" >> "$bashrc_file"
   	    echo "" >> "$bashrc_file"
   	    echo "    if (( size >= 1024**3 )); then" >> "$bashrc_file"
   	    echo "        gb=\$((size / 1024**3))" >> "$bashrc_file"
   	    echo "        size=\$((size % 1024**3))" >> "$bashrc_file"
     	    echo "    fi" >> "$bashrc_file"
   	    echo "" >> "$bashrc_file"
   	    echo "    if (( size >= 1024**2 )); then" >> "$bashrc_file"
   	    echo "        mb=\$((size / 1024**2))" >> "$bashrc_file"
   	    echo "        size=\$((size % 1024**2))" >> "$bashrc_file"
   	    echo "    fi" >> "$bashrc_file"
    	    echo "" >> "$bashrc_file"
   	    echo "    if (( size >= 1024 )); then" >> "$bashrc_file"
   	    echo "        kb=\$((size / 1024))" >> "$bashrc_file"
   	    echo "        size=\$((size % 1024))" >> "$bashrc_file"
   	    echo "    fi" >> "$bashrc_file"
   	    echo "" >> "$bashrc_file"
	    echo "    if (( \$gb >= 1 )); then" >> "$bashrc_file"
	    echo '        echo "Vous avez depasser 1000Mo Attention !!!"' >> "$bashrc_file"
	    echo "    fi" >> "$bashrc_file"
	    echo "" >> "$bashrc_file"
   	    echo '    echo "${gb}Go,${mb}Mo,${kb}Ko et ${size}octets"' >> "$bashrc_file"
   	    echo "}" >> "$bashrc_file"
            echo "" >> "$bashrc_file"
            echo "# Affichage de la taille du répertoire personnel" >> "$bashrc_file"
            echo 'dir_size=$(du -s "$HOME" | cut -f1)' >> "$bashrc_file"
            echo 'converted_size=$(convert_size "$dir_size")' >> "$bashrc_file"
            echo 'echo "Taille du répertoire personnel : $converted_size"' >> "$bashrc_file"
        fi
    fi
done
