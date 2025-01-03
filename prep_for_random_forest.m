% create average time courses for each parcel in Schaefer atlas

% loading participant data
datapath = '/home/zachkaras/fmri/preprocessed2/';
files = dir(datapath); for i=3:numel(files); fnames{i-2}=files(i).name; end % find the file names to analyze in the current directory
% remove mindy participants 113,181,210, 236,249

% mask files / important variables
maskfile = '/home/zachkaras/fmri/analysis/atlases/MNI152_T1_2mm_brain_mask.nii.gz'; % change the path as needed
mask = niftiread(maskfile); % loads the full 91x109x91 mask
brain_idx = find(mask>0); % identifies only the voxels of the brain

atlas = niftiread('/home/zachkaras/fmri/analysis/atlases/Schaefer2018_400Parcels_7Networks_order_FSLMNI152_2mm.nii.gz'); % let's pretend this is a result or seed region file
atlas_2d_brain = atlas(brain_idx); % reshapes to 2d within the brain
atlas_2d = atlas(:);
% iterate through Schaefer atlas to get indices for each parcel
for i=1:400
    parcels{i} = find(atlas_2d_brain == i);
end

% seed_vals = [58,133,192,339,377,395]; % Updated 3/3/20204
seed_vals = [133,172,192,284,339,395]; % Updated 3/11/2024 - realized right and left hemisphere are switched in atlas
% seed_vals = [9,67,176,183,231,242,341,343,348,380,386,389,391]; % Data driven, updated 3/11/2024
seed_vals = [9,67,133,172,176,183,192,231,242,284,339,341,343,348,380,386,389,391,395]; % Updated 3/11/2024 - realized right and left hemisphere are switched in atlas

for i=1:numel(seed_vals)
    seed_masks_2d{i} = find(atlas_2d_brain == seed_vals(i));
end

rev_parcels = [];
non_parcels = [];

for f=1:numel(fnames)
    tic
    if regexp(fnames{f}, '102_')
        continue
    end
    timecourses = [];
    % Load and shape the data:
    disp(['subject ',num2str(f),' of ',num2str(numel(fnames)),':', fnames{f}]);
    restdata = niftiread(fnames{f}); % load the data
    restdata_2d = reshape(restdata, numel(mask), size(restdata,4)); % reshape it to 2D (voxels x timepoints)
    restdata_2dbrain = restdata_2d(brain_idx,:); % narrow it down to only the voxels in the brain mask (which importantly matches the size of the atlases!)
    % Analyze and save results:
    
    % code for getting timecourse for each seed region
    for i=1:numel(parcels) % creates a seed ROIs x timepoints matrix of the average time series in each seed ROI
        timecourses(i,:) = nanmean(restdata_2dbrain(parcels{i},:));
    end
    
    if regexp(fnames{f}, '002_')
        rev_parcels = cat(3, rev_parcels, timecourses);
    elseif regexp(fnames{f}, '101_')
        non_parcels = cat(3, non_parcels, timecourses);
    end

    for s=1:numel(seed_vals)
        seed_timecourse = timecourses(seed_vals(s),:);
        [Correlations_noncs(f,:,s), p_vals_noncs(f,:,s)] = corr(seed_timecourse', timecourses', 'rows', 'pairwise', 'type','pearson');      
    end
    toc
end


rev_parcels(isnan(rev_parcels)) = 0;
non_parcels(isnan(non_parcels)) = 0;

mean_rev_mat = mean(rev_parcels, 3);
mean_non_mat = mean(non_parcels, 3);

corr_rev = corr(mean_rev_mat');
corr_non = corr(mean_non_mat');

corr_rev_z = atanh(corr_rev);
corr_non_z = atanh(corr_non);

writematrix(corr_rev_z, "./midprocessing/0423_corr_rev_z.csv")
writematrix(corr_non_z, "./midprocessing/0423_corr_non_z.csv")


Correlations_noncs(isnan(Correlations_noncs))=0;

rev_connectivity = Correlations_noncs(1:37,:,:);
non_connectivity = Correlations_noncs(38:end,:,:);

rev_connectivity = atanh(rev_connectivity); % Z - scoring each study separately
non_connectivity = atanh(non_connectivity);

Correlationz_data_driven = atanh(Correlations_data_driven);
Correlationz_noncs = atanh(Correlations_noncs);

for i=1:numel(seed_vals)
    temp = Correlationz_data_driven(:,:,i);
    temp(:,seed_vals(i)) = [];
    Correlationz_data_driven2(:,:,i) = temp;
end

for i=1:numel(seed_vals)
    temp = Correlationz_noncs(:,:,i);
    temp(:,seed_vals(i)) = [];
    Correlationz_noncs2(:,:,i) = temp;
end

for i=1:numel(seed_vals)
    temp = Correlations(:,:,i);
    temp(:,seed_vals(i)) = [];
    Correlations2(:,:,i) = temp;
end

for i=1:numel(seed_vals)
    temp = rev_connectivity(:,:,i);
    temp(:,seed_vals(i)) = [];
    rev_connectivity2(:,:,i) = temp;
end

for i=1:numel(seed_vals)
    temp = non_connectivity(:,:,i);
    temp(:,seed_vals(i)) = [];
    non_connectivity2(:,:,i) = temp;
end



novices = {'001_161','003_150','003_151','003_203','003_125','001_151','001_153','001_154','001_158','001_162','001_166',...
    '001_167','001_170','001_175','003_119','003_121','003_130','003_131','003_133','003_134','003_140','003_142','003_144','003_112','003_141'};
interms = {'001_155','001_160','001_165','001_173','003_105','003_109','003_118','003_122','003_129','003_138','003_143','003_147',...
    '001_152','001_156','001_157','001_163','001_174','001_177','001_178','001_181','001_182','001_183','003_101','003_102','003_108','003_111'};
experts = {'001_159','001_168','001_176','001_180','003_201','001_172','001_201','001_171','001_203','001_169','001_179','001_200','001_202','001_204'};

all_ids = regexprep(fnames, '.nii','');
nov_idx = find_group_members(novices, all_ids);
int_idx = find_group_members(interms, all_ids);
exp_idx = find_group_members(experts, all_ids);

nov_connectivity = Correlationz_data_driven(nov_idx,:,:);
int_connectivity = Correlationz_data_driven(int_idx,:,:);
exp_connectivity = Correlationz_data_driven(exp_idx,:,:);
% rev_connectivity = Correlationz_noncs2(1:37,:,:);
% non_connectivity = Correlationz_noncs2(38:end,:,:);



for i=1:numel(seed_vals)
    outfilename = sprintf("/home/zachkaras/fmri/midprocessing/rev_correlationz_seed%d.csv", seed_vals(i));
    writematrix(rev_connectivity2(:,:,i), outfilename);
    outfilename = sprintf("/home/zachkaras/fmri/midprocessing/non_correlationz_seed%d.csv", seed_vals(i));
    writematrix(non_connectivity2(:,:,i), outfilename);
end


% % t-tests
% novices = {'001_161','003_150','003_151','003_203','003_125','001_151','001_153','001_154','001_158','001_162','001_166',...
%     '001_167','001_170','001_175','003_119','003_121','003_130','003_131','003_133','003_134','003_140','003_142','003_144','003_112','003_141'};
% interms = {'001_155','001_160','001_165','001_173','003_105','003_109','003_118','003_122','003_129','003_138','003_143','003_147',...
%     '001_152','001_156','001_157','001_163','001_174','001_177','001_178','001_181','001_182','001_183','003_101','003_102','003_108','003_111'};
% experts = {'001_159','001_168','001_176','001_180','003_201','001_172','001_201','001_171','001_203','001_169','001_179','001_200','001_202','001_204'};

% women = {'001_152','001_154','001_155','001_157','001_158','001_162','001_165','001_166','001_171','001_176','001_177', ...
%     '001_178','001_180','001_181','001_183','001_200','001_201','003_101','003_109','003_119','003_129','003_130','003_140', ...
%     '003_142','003_147','003_203'};
% men = {'001_151','001_153','001_156','001_159','001_160','001_161','001_163','001_167','001_168','001_169','001_170','001_172', ...
%     '001_173','001_174','001_175','001_179','001_182','001_202','001_203','001_204','003_102','003_105','003_111','003_112','003_118', ...
%     '003_121','003_122','003_125','003_131','003_133','003_134','003_138','003_141','003_143','003_144','003_150','003_151','003_201'};
% 
% men_novices = {'001_151','001_153','001_160','001_161','001_167','001_173','001_175','003_105','003_112','003_118', ...
%     '003_121','003_122','003_125','003_131','003_133','003_134','003_138','003_141','003_144','003_150','003_151'};
% wom_novices = {'001_154','001_155','001_162','001_165','001_166','003_109','003_119','003_129','003_130','003_140','003_142','003_203',};
% men_experts = {'001_156','001_159','001_163','001_168','001_169','001_172','001_174','001_179','001_182','001_202','001_203','001_204',...
%     '003_102','003_108','003_111','003_201',};
% wom_experts = {'001_152','001_157','001_171','001_176','001_177','001_181','001_183','001_200','001_201','003_101',};



% all_ids = regexprep(fnames, '.nii.gz','');
% nov_idx = find_group_members(novices, all_ids);
% int_idx = find_group_members(interms, all_ids);
% exp_idx = find_group_members(experts, all_ids);
% men_idx = find_group_members(men, all_ids);
% wom_idx = find_group_members(women, all_ids);
% men_nov_idx = find_group_members(men_novices, all_ids);
% wom_nov_idx = find_group_members(wom_novices, all_ids);
% men_exp_idx = find_group_members(men_experts, all_ids);
% wom_exp_idx = find_group_members(wom_experts, all_ids);

% 
% nov_connectivity = Correlationz(nov_idx,:,:);
% int_connectivity = Correlationz(int_idx,:,:);
% exp_connectivity = Correlationz(exp_idx,:,:);
% men_connectivity = Correlationz(men_idx,:,:);
% wom_connectivity = Correlationz(wom_idx,:,:);
% men_nov_connectivity = Correlationz2(men_nov_idx,:,:);
% wom_nov_connectivity = Correlationz2(wom_nov_idx,:,:);
% men_exp_connectivity = Correlationz2(men_exp_idx,:,:);
% wom_exp_connectivity = Correlationz2(wom_exp_idx,:,:);

% 
% 
% n_nov = size(nov_connectivity,3);
% n_int = size(int_connectivity,3);
% n_exp = size(exp_connectivity,3);
% n_men = size(men_connectivity,3);
% n_wom = size(wom_connectivity,3);

qvals = [];
% ne_qvals = [];
% ni_qvals = [];
for i=1:numel(seed_vals)
    fprintf("\nSeed %d\n", seed_vals(i))
    % nov_data = squeeze(nov_connectivity(:,:,i));
    % int_data = squeeze(int_connectivity(:,:,i));
    % exp_data = squeeze(exp_connectivity(:,:,i));
    rev_data = squeeze(rev_connectivity(:,:,i));
    non_data = squeeze(non_connectivity(:,:,i));

    % men_nov_data = squeeze(men_nov_connectivity(:,:,i));
    % wom_nov_data = squeeze(wom_nov_connectivity(:,:,i));
    % men_exp_data = squeeze(men_exp_connectivity(:,:,i));
    % wom_exp_data = squeeze(wom_exp_connectivity(:,:,i));
    
    % [~,nov_exp_pvals(i,:),~,nov_exp_stats(i,:)] = ttest2(exp_data, nov_data); % calculate t statistics
    % [~,nov_int_pvals(i,:),~,nov_int_stats(i,:)] = ttest2(nov_data, int_data); % calculate t statistics
    [~,rev_non_pvals(i,:),~,rev_non_stats(i,:)] = ttest2(rev_data, non_data); % calculate t statistics

    % [~,men_v_men_pvals(i,:),~,men_v_men_stats(i,:)] = ttest2(men_nov_data, men_exp_data); % calculate t statistics
    % [~,wom_v_wom_pvals(i,:),~,wom_v_wom_stats(i,:)] = ttest2(wom_nov_data, wom_exp_data); % calculate t statistics
    % [~,men_v_wom_exp_pvals(i,:),~,men_v_wom_exp_stats(i,:)] = ttest2(men_exp_data, wom_exp_data); % calculate t statistics
    % [~,men_v_wom_nov_pvals(i,:),~,men_v_wom_nov_stats(i,:)] = ttest2(men_nov_data, wom_nov_data); % calculate t statistics
    % [ne_m_h, ne_m_crit_p, ne_m_adj_ci_cvrg, ne_m_adj_p]=fdr_bh(men_v_men_pvals(i,:),0.05);
    % [ne_w_h, ne_w_crit_p, ne_w_adj_ci_cvrg, ne_w_adj_p]=fdr_bh(wom_v_wom_pvals(i,:),0.05);
    % [n_m_w_h, n_m_w_crit_p, n_m_w_adj_ci_cvrg, n_m_w_adj_p]=fdr_bh(men_v_wom_nov_pvals(i,:),0.05);
    % [e_m_w_h, e_m_w_crit_p, e_m_w_adj_ci_cvrg, e_m_w_adj_p]=fdr_bh(men_v_wom_exp_pvals(i,:),0.05);
    
    % disp(sum(ne_m_h))
    % disp(sum(ne_w_h))
    % disp(sum(n_m_w_h))
    % disp(sum(e_m_w_h))


    % [ni_h, ni_crit_p, ni_adj_ci_cvrg, ni_adj_p]=fdr_bh(nov_int_pvals(i,:),0.05);
    % [ne_h, ne_crit_p, ne_adj_ci_cvrg, ne_adj_p]=fdr_bh(nov_exp_pvals(i,:),0.05);
    [rn_h, rn_crit_p, rn_adj_ci_cvrg, rn_adj_p]=fdr_bh(rev_non_pvals(i,:), 0.01);
    % ni_sorted = sort(nov_int_pvals(i,:));
    % ne_sorted = sort(nov_exp_pvals(i,:));
    % ni_locations = find(nov_int_pvals(i,:) == ni_sorted(1:5));
    % ne_locations = find(nov_exp_pvals(i,:) == ne_sorted(1:5));
    % ni = length(ni_locations);
    % ne = length(ne_locations);
    % disp(sum(ni_h))
    % disp(sum(ne_h))
    qvals = cat(1,qvals, rn_adj_p);
    % ne_qvals = cat(1,ne_qvals, ne_adj_p);
    % ni_qvals = cat(1,ni_qvals, ni_adj_p);

    num_sig = sum(rn_h);
    disp(num_sig)


    % disp(max(rev_non_stats(i).tstat))
    % disp(min(rev_non_stats(i).tstat))
    % find(rn_h == 1)
    if isnan(num_sig) || num_sig <= 0
        continue
    else
        make_parcel_brains(seed_vals(i), rn_h, rev_non_stats(i).tstat, empty_brain, brain_idx, parcels, nii_template);
    end
    % disp(sum(ne_h))
    % disp(ni_sorted(1))
    % disp(ni_locations(1:ni))
    % disp(ne_sorted(1))
    % disp(ne_locations(1:ne))
    % make_parcel_brains(seed_vals(i), rn_h, rev_non_stats(i).tstat, empty_brain, brain_idx, parcels, nii_template);
    % create an empty brain
    % new_brain = empty_brain;

    % significant parcel indexes should equal the t-stat
    % zero out parcels except for significant ones
    % new_parcel_idx = cell(1,400);
    % new_parcel_idx(rn_h) = parcels(rn_h);

    % new_brain(brain_idx) 
    % new_parcels = zeros(1,400);

    % where there's a significant correlation in rn_h, 
    % new_parcels(rn_h) = rev_non_stats.tstat(i, rn_h);

    
    % disp(new_parcels)
    % parcels with significant activation
    % new_brain(parcels{})
    % make the value the t-stat associated with the indexes where h is 1
    

    % fprintf("min nov/int q: %d | min nov/exp q: %d")
    % break
end

tstats = [];
for i=1:numel(rev_non_stats)
    tstats = cat(1,tstats,rev_non_stats(i).tstat);
end

writematrix(tstats, "./midprocessing/0423_rev_non_tstats.csv")
writematrix(qvals, "./midprocessing/0423_rev_non_qvals.csv")

yrs_experience = [2,4,2,2,3,4,4,5,3,1,2,4,3,2,2,5,10,8,6,3,4,2,5,4,10,4,4,4,10,7,12,8,12,4,4,3,4,3,4 ...
    2.5,3,2,2,3,1.5,3,2,2,2,2,3,2,2.5,2,2,1,1,5,1];
age = [21,21,19,21,20,21,22,22,19,18,20,21,21,18,21,22,26,22,26,21,22,24,24,27,27,21,22,22,23,23,25,23 ...
    24,24,21,21,22,23,22,21,21,20,22,21,20,19,19,22,20,19,23,20,20,19,20,19,20,25,25];
X = [yrs_experience; age]';

% x = yrs_experience; %Population of states
% y = Correlationz(:,98,1)';
y = Correlationz(:,9,1)';
% y = Correlationz(:,142,1)';
% y = Correlationz(:,5,1)'; 
% y = Correlationz(:,379,1)';
% y = Correlationz(:,150,1)';
% y = Correlationz(:,124,1)';
% y = Correlationz(:,9,1)';
% y = Correlationz(:,389,1)';
% y = Correlationz(:,166,1)';
% y = Correlationz(:,150,1)';

mdl = fitlm(X,y);
mdl
scatter(yrs_experience,y)

% mdl = fitlm
format long

b1 = x\y;

yCalc1 = b1*x;

hold on
plot(x,yCalc1)
xlabel('Years of Experience')
ylabel('Correlation Values')

grid on


