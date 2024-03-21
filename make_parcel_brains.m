function make_parcel_brains(seed, sig_idx, stats, empty_brain, brain_idx, parcels, nii_template)
    new_brain_neg = empty_brain;
    new_brain_pos = empty_brain;

    sig_parcels = cell(1,400);
    sig_parcels(sig_idx) = parcels(sig_idx);
    
    sig_values = zeros(1,400);
    sig_values(sig_idx) = stats(sig_idx);

    for p = 1:numel(parcels)
        if ~isempty(parcels{p})
            parcel_idx = parcels{p};
            whole_brain_idx = brain_idx(parcel_idx);
            if sig_values(p) > 0
                new_brain_pos(whole_brain_idx) = sig_values(p);
            elseif sig_values(p) < 0
                new_brain_neg(whole_brain_idx) = sig_values(p);
            end
        end
    end

    if sum(new_brain_neg(:)) ~= 0
        filename = sprintf("/home/zachkaras/fmri/results/parcel_map_seed%d_neg_p05",seed);
        write_nii_cc(nii_template, new_brain_neg, filename);
        compress_file = sprintf("gzip /home/zachkaras/fmri/results/parcel_map_seed%d_neg_p05.nii", seed);
        system(compress_file);
    if sum(new_brain_pos(:)) ~= 0
        filename = sprintf("/home/zachkaras/fmri/results/parcel_map_seed%d_pos_p05",seed);
        write_nii_cc(nii_template, new_brain_pos, filename);
        compress_file = sprintf("gzip /home/zachkaras/fmri/results/parcel_map_seed%d_pos_p05.nii", seed);
        system(compress_file);
    end
    
end