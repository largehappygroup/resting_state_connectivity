#!/bin/bash

# for loop to find files
find ../codeprose -maxdepth 1 -type d | while read -r folder; do
      foldername="${folder:13}"
      if echo "$foldername" | grep -E -q 'out_[0-9]{3}$'; then
            echo "moving $foldername"
            file="../codeprose/$foldername/all_warped.nii.gz"
            cp "$file" "../preprocessed/${foldername}.nii.gz" 
      fi
done

