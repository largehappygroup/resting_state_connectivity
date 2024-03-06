#/bin/bash

# iterating through correlation maps for each seed region
for file in ../midprocessing/*.nii.gz; do
      GROUP="${file:17:26}" # getting the specific group names (e.g., nov_exp_seed008)
      #echo "$GROUP"
      if [[ $GROUP =~ "two_groups" ]]; then
            DESIGN="two_groups_design.mat"
            #T=2.00;
            #continue
      elif [[ $GROUP =~ "exp" ]]; then 
            DESIGN="nov_exp_design.mat" 
            #T=2.03; 
            continue
      elif [[ $GROUP =~ "int" ]]; then 
            DESIGN="nov_int_design.mat" 
            #T=2.02;
            continue
      elif [[ $GROUP =~ "men" ]]; then
            DESIGN="men_wom_design.mat"
            continue
      fi
      GROUP="${file:17:18}"
      OUTFILE="../results/${GROUP}"
      echo "$GROUP" 
      nice -n 20 randomise_parallel -i "$file" -o "$OUTFILE" -d "$DESIGN" -t design.con -m atlases/MNI152_T1_2mm_brain_mask.nii.gz -n 5000 -T
      
      NEW_INPUT1="${OUTFILE}_tfce_corrp_tstat1.nii.gz"
      NEW_INPUT2="${OUTFILE}_tstat1.nii.gz"
      NEW_OUTPUT="${OUTFILE}_thresh"

      nice -n 20 fslmaths "$NEW_INPUT1" -thr 0.95 -bin -mul "$NEW_INPUT2" "$NEW_OUTPUT" 
done
