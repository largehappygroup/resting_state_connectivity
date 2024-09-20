%% Calculating t-stats, correcting for multiple comparisons, and saving results
% Results are saved in both csv files and 4d nifti files for visualization
[stats, qvals] = calculate_stats(a_connectivity, b_connectivity, seed_vals, empty_brain, brain_idx, parcels, nii_template);


tstats = [];
for i=1:numel(stats)
    tstats = cat(1,tstats,stats(i).tstat);
end

% exporting results
writematrix(tstats, "./sample_results/tstats.csv")
writematrix(qvals, "./sample_results/qvals.csv")

% Loops through seed values to calculate t-stats between groups
% corrects for multiple comparisons
function [stats, qvals] = calculate_stats(grp1_connectivity, grp2_connectivity, seed_vals, empty_brain, brain_idx, parcels, nii_template)

    % Calculates stats separately for each seed region
    % So this calculates stats based on the FC measures between seed
    % regions and other parcels in the Schafer atlas
    qvals = [];
    for i=1:numel(seed_vals)
        fprintf("\nSeed %d\n", seed_vals(i))
        grp1_data = squeeze(grp1_connectivity(:,:,i));
        grp2_data = squeeze(grp2_connectivity(:,:,i));
        
        [~,pvals(i,:),~,stats(i,:)] = ttest2(grp1_data, grp2_data); % calculate t statistics
    
        % corrects for multiple comparisons using benjamini hochberg method
        [h, crit_p, adj_ci_cvrg, adj_p]=fdr_bh(pvals(i,:), 0.01);
        
        qvals = cat(1,qvals, adj_p);
    
        num_sig = sum(h);
        disp(num_sig)
    
        % This code creates nifti files for the results
        if isnan(num_sig) || num_sig <= 0
            continue
        else
            make_parcel_brains(seed_vals(i), h, stats(i).tstat, empty_brain, brain_idx, parcels, nii_template);
        end
    end
end
