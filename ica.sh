#/bin/bash
# after preprocessing 

perform_ica(){
      melodic -i "$1/filtered_func_data.nii.gz" -d 60 -o "$1/filtered_func_data.ica/" --Oorig --report --tr=0.8 -v 
}

format_for_fix(){
      echo "formatting output directory for FIX"
      mkdir "$1/mc"
      mkdir "$1/reg"
      
      mv "$1/st_mc.nii.par" "$1/mc/prefiltered_func_data_mcf.par"
      fslroi "$1/filtered_func_data.nii.gz" "$1/reg/example_func.nii.gz" 0 1

      # create mask for 4D functional data
      flirt -in "$1/BrainExtractionMask.nii.gz" -ref "$1/reg/example_func.nii.gz" -out "$1/mask.nii.gz" -applyxfm -usesqform
      
      # create temporal mean of 4d data
      fslmaths "$1/filtered_func_data.nii.gz" -Tmean "$1/mean_func.nii.gz"
      
      # move example anatomical to reg/highres.nii.gz
      mv "$1/BrainExtractionBrain.nii.gz" "$1/reg/highres.nii.gz"
      flirt -in "$1/reg/highres.nii.gz" -ref "$1/reg/example_func.nii.gz" -out "$1/reg/highres2example_func" -omat "$1/reg/highres2example_func.mat"

}

perform_fix(){
      ~/fix/fix -c "$1" ~/fix/training_files/UKBiobank.RData 20
}

# read out folders in output directory

# enter each one

# perform melodic
#melodic -i '/home/zachkaras/fmri/temp2/out_001_151/raw_mc_epi2mni.nii.gz' -d 60 -o '/home/zachkaras/fmri/temp2/out_001_151/ica_60comps' --Oorig --report --tr=0.8 -v

# perform steps for running FIX

# for loop here for going through output directories  
datadir="/home/zachkaras/fmri/out_003_111"
perform_ica "$datadir"
format_for_fix "$datadir"
perform_fix "$datadir"

