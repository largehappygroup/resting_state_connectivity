#!/bin/bash

# for loop to find files
find ../three_studies_raw -maxdepth 1 -type d | while read -r folder; do
      foldername="${folder:21}"
      if echo "$foldername" | grep -E -q 'out_[0-9]{3}'; then
            file="../three_studies_raw/$foldername/all_warped.nii.gz"
            echo "moving $file" #to ../preprocessed/${foldername:4:7}.nii.gz"
            cp "$file" "../preprocessed/${foldername:4:7}.nii.gz" 
      fi
done

