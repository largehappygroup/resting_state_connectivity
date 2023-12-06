function corrected_pvals = bonferroni(pvals)
    num_voxels = length(pvals);
    corrected_pvals = pvals * num_voxels;
    corrected_pvals(corrected_pvals > 1) = 1;
    % corrected_alpha = 0.05 / num_voxels;
    
    % corrected_pval_indices = pvals < corrected_alpha;
    
end