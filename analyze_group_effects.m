% Takes in 3d matrix of seed to voxel correlation values 
% subj_matrix should already be z-transformed
function analyze_group_effects(subj_matrix, seed_masks, seed_vals, brain_idx, mni_brain, nii_template, studyname)
    nii_template.img = zeros(size(nii_template.img)); % replace the mask with all 0s
    empty_brain = nii_template.img; % create an empty_brain image in the template's shape
    % subj_matrix_z = atanh(subj_matrix); % use Fisher's z transformation to make the correlation coefficients follow a more normal distribution (if wanted)

    % Evaluate the group-level effect of the FC from each seed to each voxel (e.g., to visualize results):
    for i=1:numel(seed_masks)
        [~,pvals(i,:),~,stats(i,:)] = ttest(squeeze(subj_matrix(i,:,:))',0); % calculate t statistics
        
        % Save the resulting t statistics to a brain image in a NIfTI file for hypothesis testing and visualization:
        grp_seedvox_t = empty_brain;
        grp_seedvox_t(brain_idx) = stats(i).tstat;

        % threshold = benjamini_hochberg(pvals(i,:));
        threshold = bonferroni(pvals(i,:));
        significant_mask = empty_brain;
        significant_mask(brain_idx) = pvals(i,:) < threshold;
        significant_mask = reshape(significant_mask, [91,109,91]);
        
        plot_slices(seed_vals(i), significant_mask, mni_brain, studyname)
    end
end