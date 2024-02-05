#!/bin/bash

extract_functional(){
      echo "extracting functional scan"
      fslsplit $1 temp_vol -t
      ls temp_vol*.nii.gz | nice parallel "bet {} {}_brain -f 0.3"
      fslmerge -t "$2/func_brain.nii.gz" temp_vol*_brain.nii.gz
      rm temp_vol*.nii.gz
}

register_functional(){
      echo "applying transformations to functional scan"
      fslsplit $1 temp_vol -t
      ls temp_vol*.nii.gz | nice parallel "antsApplyTransforms -d 3 -i {} -r $2/Warped.nii.gz -o {}_warped.nii -t $2/1Warp.nii.gz -t $2/0GenericAffine.mat"
      fslmerge -t "$2/raw_mc_epi2mni.nii" temp_vol*_warped.nii
      rm temp_vol*.nii
}

preprocess(){       
      echo "brain extraction"
      bet $1 "$3/anat_brain.nii" -o -m -f 0.3
      extract_functional $2 $3 # arg 1 is functional scan, arg 2 is output directory

      echo "motion correction"
      mcflirt -in "$3/func_brain.nii.gz" -out "$3"/st_mc.nii -mats -plots

      # picking reference volume for registration
      fslroi "$3"/st_mc.nii.gz "$3"/reference.nii.gz 0 1
      
      echo "registration to anatomical scan"
      epi_reg --epi="$3/reference.nii.gz" \
              --t1=$1 \
              --t1brain="$3/anat_brain.nii.gz" \
              --out="$3/subject_registration.nii" \
      
      echo "registration to MNI"
      antsRegistrationSyNQuick.sh -d 3 \
            -f "./atlases/MNI152_T1_2mm_brain.nii.gz" \
            -m "$3/anat_brain.nii.gz" \
            -o "$3/" \

      echo "applying to all volumes"
      register_functional "$3/func_brain.nii.gz" $3 
     
      echo "smoothing"
      fslmaths "$3/raw_mc_epi2mni.nii" -kernel gauss 3 -fmean "$3/all_warped.nii"
}

# for loop going through all participant folders 
count=0

find ../three_studies_raw/ -maxdepth 1 -type d | while read -r folder; do
      foldername="${folder:21}"
      if [[ "$foldername" =~  ^[0-9]{3}_[0-9]{3}$ ]]; then
            echo $foldername
            mkdir "../three_studies_raw/out_$foldername" 
            echo "Processing folder $foldername"
            ANATFILE="../three_studies_raw/$foldername/ht1spgr_208sl.nii"
            FUNCFILE="../three_studies_raw/$foldername/utprun_01.nii"
            OUT="../three_studies_raw/out_$foldername"
            preprocess $ANATFILE $FUNCFILE $OUT
      fi
done



