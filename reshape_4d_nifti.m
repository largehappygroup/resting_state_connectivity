function reshaped_volumes = reshape_4d_nifti(n, data, brain_idx, empty_brain)
    reshaped_volumes = [];
    for i=1:n
        sub_data = data(:,:,i);
        vol = empty_brain;
        vol(brain_idx) = sub_data;
        reshaped_volumes = cat(4,reshaped_volumes,vol);
    end
end