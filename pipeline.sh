#!/bin/bash

extract_functional(){
      echo "extracting functional scan"
      fslsplit "$1/st_mc.nii.gz" temp_vol -t
      
      ls temp_vol*.nii.gz | nice parallel "fslmaths {} -mas $1/resampled_anatomical_mask.nii.gz {}_brain"
      fslmerge -t "$1/func_brain.nii.gz" temp_vol*_brain.nii.gz
      rm temp_vol*.nii.gz
}

register_functional(){
      echo "applying transformations to functional scan"
      fslsplit $1 temp_vol -t
      ls temp_vol*.nii.gz | nice parallel "antsApplyTransforms -d 3 -i {} -r $2/Warped.nii.gz -o {}_warped.nii -t $2/1Warp.nii.gz -t $2/0GenericAffine.mat -t $2/epi_2_anat_0GenericAffine.mat"
      fslmerge -t "$2/raw_mc_epi2mni.nii" temp_vol*_warped.nii
      rm temp_vol*
}

preprocess(){       
      echo "brain extraction"
      # bet $1 "$3/anat_brain.nii" -o -m -f 0.3
      antsBrainExtraction.sh -d 3 -a $1 -e "atlases/MNI152_T1_2mm.nii.gz" -m "atlases/MNI152_T1_2mm_brain_mask.nii.gz" -o "$3/" 
      
      echo "motion correction"
      mcflirt -in $2 -out "$3"/st_mc.nii -mats -plots
      # picking reference volume for registration
      fslroi "$3"/st_mc.nii.gz "$3"/reference.nii.gz 0 1
       
      echo "resampling anatomical mask"
      flirt -in "$3/BrainExtractionMask.nii.gz" -ref "$3/reference.nii.gz" -out "$3/resampled_anatomical_mask.nii.gz" -applyxfm -usesqform

      echo "masking functional scan"
      extract_functional $3

      echo "registration to anatomical scan"
      # epi_reg --epi="$3/reference.nii.gz" \
      #         --t1=$1 \
      #         --t1brain="$3/BrainExtractionBrain.nii.gz" \
      #         --out="$3/subject_registration.nii" \
      antsRegistrationSyNQuick.sh -d 3 \
            -f $1 \
            -m "$3/reference.nii.gz" \
            -o "$3/epi_2_anat_" \

      echo "registration to MNI"
      antsRegistrationSyNQuick.sh -d 3 \
            -f "./atlases/MNI152_T1_2mm_brain.nii.gz" \
            -m "$3/BrainExtractionBrain.nii.gz" \
            -o "$3/" \

      echo "applying to all volumes"
      register_functional "$3/func_brain.nii" $3 
      
      echo "smoothing"
      fslmaths "$3/raw_mc_epi2mni.nii" -kernel gauss 3 -fmean "$3/all_warped.nii"
}

# for loop going through all participant folders 
count=0

find ../temp2/ -maxdepth 1 -type d | while read -r folder; do
      foldername="${folder:9}"
      if [[ "$foldername" =~  ^[0-9]{3}_[0-9]{3}$ ]]; then
            echo $foldername
            mkdir "../temp2/out_$foldername" 
            echo "Processing folder $foldername"
            ANATFILE="../temp2/$foldername/ht1spgr_208sl.nii"
            FUNCFILE="../temp2/$foldername/utrun_01.nii"
            OUT="../temp2/out_$foldername"
            preprocess $ANATFILE $FUNCFILE $OUT
      fi
done



