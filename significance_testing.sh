#/bin/bash

randomise -i ../results/nov_exp_seed8.nii.gz -o ../results/nov_exp_t -d nov_exp_design.mat -t design.con -m atlases/MNI152_T1_2mm_brain_mask.nii.gz -n 500 -T -C 2.03

fslmaths ../results/nov_exp_t_tfce_corrp_tstat1.nii.gz -thr 0.95 -bin -mul ../results/nov_exp_t_tstat1.nii.gz thresh_test
