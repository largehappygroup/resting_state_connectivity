#!/bin/bash

# I'm using this script to get only the files that I need from all three fmri studies
# The folder hierarchies are slightly different for each study, so I made a different function for copying each  

# Anatomical file: ht1spgr_208sl.nii 
# Functional file: utrun_01.nii -> shapes study has utprun_01.nii 

# I also need to rename the participants since there's some overlap
# but you may not need to do that for your data
get_physio_files(){
      data="$1"
      outdir="$2"
      mkdir "$outdir"
      datfile=$(find "$data" -type f -name "*reference.dat")
      grep "func_rest" "$datfile" | awk '{print $6, $7, $8, $9, $10}' | while read -r file1 file2 file3 file4; do
            cp "$data/physio/$file1" "$outdir"
            cp "$data/physio/$file2" "$outdir"
            cp "$data/physio/$file3" "$outdir"
            cp "$data/physio/$file4" "$outdir"
      done
}


# function for copying files from the mental rotation study 
copy_shapes(){
      shapes_dir="/storage2/fmridata/fmri-data-shapes/"
      find "$shapes_dir" -maxdepth 1 -type d | while read -r folder; do
           foldername="${folder:36}"
           if echo "$foldername" | grep -E -q '[0-9]{3}'; then
                 echo "$foldername"
                 for wrw_dir in "$folder"/wrw*/; do
                       if [ -d "$wrw_dir" ]; then
                             newpid="001_$foldername"
                             newdir="/home/zachkaras/fmri/three_studies_raw/$newpid/"
                             mkdir "$newdir"
                             anat="$wrw_dir/anatomy/t1spgr_208sl/ht1spgr_208sl.nii"
                             func="$wrw_dir/func/rest/run_01/utrun_01.nii"
                             physio="$wrw_dir/raw/physio"
                             get_physio_files "$wrw_dir/raw/" "$newdir/physio"
                             cp "$anat" "$newdir"
                             cp "$func" "$newdir"
                             #echo $newpid $physio $newdir
                       fi
                 done
           fi
      done
}

copy_review(){
      review_dir="/storage2/fmridata/fmri-data-codereview/fmri-scans/"
      find "$review_dir" -maxdepth 1 -type d | while read -r folder; do
           foldername="${folder:51}"
           if echo "$foldername" | grep -E -q 'wrw*'; then
                 newpid="002_${foldername:10:3}"
                 newdir="/home/zachkaras/fmri/two_studies_raw/$newpid/"
                 echo "$newpid"
                 mkdir "$newdir"
                 anat="$review_dir/$foldername/anatomy/t1spgr_208sl/t1spgr_208sl.nii"
                 func="$review_dir/$foldername/func/rest/run_01/tprun_01.nii"
                 # code review was already corrected for physiological data
                 cp "$anat" "$newdir"
                 cp "$func" "$newdir"

           fi 
      done
}

# copying code writing data
copy_writing(){
      writing_dir="/storage2/fmridata/fmri-data-codesynth/"
      find "$writing_dir" -maxdepth 1 -type d | while read -r folder; do
            foldername="${folder:39}"
            if echo "$foldername" | grep -E -q '^[0-9]{3}$'; then
                  echo "$foldername" 
                  newpid="003_$foldername"
                  newdir="/home/zachkaras/fmri/three_studies_raw/$newpid/"
                  mkdir "$newdir"
                  anat="$folder/fmri-scan/anatomy/t1spgr_208sl/ht1spgr_208sl.nii"
                  func="$folder/fmri-scan/func/rest/run_01/utrun_01.nii"
                  physio="/storage2/fmridata/fmri-data-codesynth/$foldername/fmri-scan/raw/physio"
                  get_physio_files "/storage2/fmridata/fmri-data-codesynth/$foldername/fmri-scan/raw" "$newdir/physio"
                  cp "$anat" "$newdir"
                  cp "$func" "$newdir"

            fi
      done
}

copy_noncs(){
      noncs_dir="/home/zachkaras/fmri/non-cs"
      noncs_func_dir="$noncs_dir/Functional/"
      noncs_anat_dir="$noncs_dir/Anatomy/"
      for file in "$noncs_func_dir"*; do
            #echo "$file"
            new_id="101_${file:44:3}"
            new_dir="/home/zachkaras/fmri/two_studies_raw/$new_id"
            mkdir "$new_dir"
            cp "$file" "$new_dir/tprun_01.nii"
      done

      for file in "$noncs_anat_dir"*; do
            new_id="101_${file:41:3}"
            new_dir="/home/zachkaras/fmri/two_studies_raw/$new_id"
            cp "$file" "$new_dir/t1spgr_156sl.nii"
      done
}


#copy_shapes
copy_review
#copy_writing
copy_noncs


