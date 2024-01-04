function BH_threshold = benjamini_hochberg(pvals)
    [sorted_p, sort_idx] = sort(pvals);
    m = length(pvals);
    alpha = 0.01;
    BH_threshold = alpha * (1:m) / m;
    
    
    % max_significant = find(sorted_p <= BH_threshold, 1, 'last');
    % 
    % if ~isempty(max_significant)
    %     significance_threshold = sorted_p(max_significant);
    %     significant_voxels = pvals <= significance_threshold;
    % end
end