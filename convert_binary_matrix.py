import numpy as np

filename = "/home/zachkaras/fmri/temp2/out_001_151/epi_2_anat_0GenericAffine.mat"

with open(filename, 'rb') as f:
    data = f.read()

start_marker = b'AffineTransform_double_3_3\x00'
start_index = data.find(start_marker) + len(start_marker)

# Adjust the offset if there are additional bytes between the marker and the matrix data
additional_offset = 0  # Adjust this value as needed
offset = start_index + additional_offset

matrix = np.frombuffer(data[offset:], dtype=np.float64, count=12).reshape((3, 4))

fsl_matrix = np.vstack([matrix,[0,0,0,1]])

np.savetxt('/home/zachkaras/fmri/temp2/out_001_151/highres2example_func.mat', fsl_matrix)
