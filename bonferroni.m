function corrected_pval_indices = bonferroni(pvals)
    num_voxels = length(pvals);
    corrected_alpha = 0.05 / num_voxels;
    
    corrected_pval_indices = pvals < corrected_alpha;
    
end