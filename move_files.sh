#!/bin/bash

# for loop to find files
find ../two_studies_raw -maxdepth 1 -type d | while read -r folder; do
      foldername="${folder:19}"
      if echo "$foldername" | grep -E -q 'out_[0-9]{3}'; then
            file="../two_studies_raw/$foldername/filtered_func_data.nii.gz"
            echo "moving $file" #to ../preprocessed2/${foldername:4:7}.nii.gz"
            mv "$file" "../preprocessed2/${foldername:4:7}.nii.gz" 
      fi
done

