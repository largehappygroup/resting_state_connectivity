#!/bin/bash

# I'm using this script to get only the files that I need from all three fmri studies
# Anatomical file: ht1spgr_208sl.nii 
# Functional file: utrun_01.nii -> shapes study has utprun_01.nii 

# I also need to rename the participants since there's some overlap
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
                             anat="$wrw_dir/anatomy/t1spgr_208sl/ht1spgr_208sl.nii"
                             func="$wrw_dir/func/rest/run_01/utrun_01.nii"
                             physio="$wrw_dir/raw/physio"
                             get_physio_files "$wrw_dir/raw/" "$newdir/physio"
                             #mkdir "$newdir"
                             #cp "$anat" "$newdir"
                             #cp "$func" "$newdir"
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
                 newdir="/home/zachkaras/fmri/three_studies_raw/$newpid/"
                 echo "$newpid"
                 anat="$review_dir/$foldername/anatomy/t1spgr_208sl/ht1spgr_208sl.nii"
                 func="$review_dir/$foldername/func/rest/run_01/utprun_01.nii"
                 # code review was already corrected for physiological data
                 #mkdir "$newdir"
                 #cp "$anat" "$newdir"
                 #cp "$func" "$newdir"

           fi 
      done
}

copy_writing(){
      writing_dir="/home/zachkaras/fmri/codeprose/"
      find "$writing_dir" -maxdepth 1 -type d | while read -r folder; do
            foldername="${folder:31}"
            if echo "$foldername" | grep -E -q '^[0-9]{3}'; then
                  echo "$foldername"
                  newpid="003_$foldername"
                  newdir="/home/zachkaras/fmri/three_studies_raw/$newpid/"
                  anat="$folder/ht1spgr_208sl.nii"
                  func="$folder/utrun_01.nii"
                  physio="/storage2/fmridata/fmri-data-codesynth/$foldername/fmri-scan/raw/physio"
                  get_physio_files "/storage2/fmridata/fmri-data-codesynth/$foldername/fmri-scan/raw" "$newdir/physio"
                  #mkdir "$newdir"
                  #cp "$anat" "$newdir"
                  #cp "$func" "$newdir"

            fi
      done
}

copy_shapes
#copy_review
copy_writing



