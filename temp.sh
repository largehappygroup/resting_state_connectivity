#/bin/bash


while IFS= read -r line
      do
            path="/home/zachkaras/fmri/three_studies_raw/$line"
            cp -r "$path/fix" "$path/filtered_func_data.ica" 
      done < foldernames.txt




#find "/home/zachkaras/fmri/three_studies_raw/" -maxdepth 1 -type d | while read -r folder; do
#      foldername="${folder:39}"
#      if [[ "$foldername" =~ "out" ]]; then
#            echo "$foldername"
#      fi
#
#done
