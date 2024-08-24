#!/bin/bash

######## CHANGE BEFORE START ######## 
folder="amount_messages"
#####################################


# Specify the prefixes and postfixes for the CSV files to merge
prefixes=("aco" "rw" "gossips")
postfixes=("" "-fail")

# Create the results folder if it doesn't exist
mkdir -p results/${folder}

cd ${folder}

# Loop through each prefix
for prefix in "${prefixes[@]}"
do
    # Loop through each postfix
    for postfix in "${postfixes[@]}"
    do

        # Get a list of all the CSV files with the current prefix and postfix
        files=$(ls ${prefix}-*${postfix}.csv 2>/dev/null | egrep ${prefix}-[0-9][0-9][0-9]?${postfix}.csv)


        # Create a new file to hold the merged data
        merged_file="../results/${folder}/${prefix}${postfix}.csv"
        touch "$merged_file"
        
        # Loop through each file and append its data to the merged file
        first_file=true
        for file in $files
        do
            # Extract the filename from the file path
            filename=$(basename "$file")
            
            # Remove the ".csv" extension and the prefix and postfix
            filename="${filename%.csv}"
            filename="${filename#${prefix}-}"
            filename="${filename%${postfix}}"
            
            # Print the header once for the first file
            if [ $first_file = true ]
            then
                # Use head to extract the header from the file and add the "nodes" header
                echo "nodes,$(head -n 1 aco-100.csv)" > "$merged_file"
                first_file=false
            fi
            
            # Add the filename as the first column in the file
            awk -v fn="$filename" 'BEGIN {FS=OFS=","} NR>1 {print fn,$0}' "$file" >> "$merged_file"

            iconv -c -f utf-8 -t ascii "$merged_file" -o "$merged_file-temp"
            mv -i -f "$merged_file-temp" "$merged_file"
            #rm "$merged_file-temp"
        done
    done
done
