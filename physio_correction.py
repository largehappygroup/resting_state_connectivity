import os
import glob
import numpy as np
import pandas as pd
import nibabel as nib
from nilearn.image import clean_img


def downsample(lst, target_length):
    step = len(lst) // target_length
    return lst[::step][:target_length]

def retroicor(pathname, pid, P): # P is the matrix of physiological data
    fmri_path = f"{pathname}/{pid}/utrun_01*"
    matching_file = glob.glob(fmri_path)
    og_fmri = nib.load(matching_file[0])
    print("performing retroicor correction")
    corrected_scan = clean_img(og_fmri, confounds=P)
    nib.save(corrected_scan, f"{pathname}/{pid}/utprun_01.nii")
    

pathname = "/home/zachkaras/fmri/three_studies_raw"
participants = os.listdir(pathname)
scan_length = 600 # matching the 600 volumes in the resting state scans
for pid in participants:
    physio_path = f"{pathname}/{pid}/physio"
    try:
        physio_files = os.listdir(physio_path)
    except:
        continue
    
    regressors = []
    print(pid)
    for f in physio_files:
        file = open(f"{physio_path}/{f}", 'r')
        data = file.read()
        data = data.split("\n")
        if len(data) <= scan_length:
            continue
        downsampled = downsample(data, 600)
        regressors.append(downsampled)
    P = np.column_stack(regressors)
    retroicor(pathname, pid, P)







