import os
import re
import numpy as np
import nibabel as nib

# downsampling from 600 to 240
target_length = 240
nums = [x for x in range(1,601)]

step = len(nums)//target_length
downsampled = nums[::step][:target_length]

pathname = "/home/zachkaras/fmri/two_studies_raw"
participants = os.listdir(pathname)
for p in participants:
    if re.search("002",p):
        print(f"working on {p}")
        func = f"{pathname}/{p}/tprun_01.nii"
        anat = f"{pathname}/{p}/t1spgr_208sl.nii"

        ds_id = f"1{p[1:]}"
        outpath = f"/home/zachkaras/fmri/two_studies_raw/{ds_id}" 
        command = f"mkdir {outpath}"
        os.system(command)

        # copy anatomical file
        copy_command = f"cp {anat} {outpath}"
        os.system(copy_command)

        # highpass filtering
        print("highpass filtering...")
        highpass_command = f"fslmaths {func} -bptf 0.025 -1 {outpath}/hp_tprun_01.nii"
        os.system(highpass_command)

        # downsampling
        print("downsampling...")
        hp_func = nib.load(f"{outpath}/hp_tprun_01.nii.gz")
        hp_data = hp_func.get_fdata()
        ds_data = hp_data[:,:,:,::step]
        ds_data = ds_data[:,:,:,:target_length]
        ds_image = nib.Nifti1Image(ds_data, affine=hp_func.affine, header=hp_func.header)
        nib.save(ds_image, f"{outpath}/tprun_01.nii.gz")

