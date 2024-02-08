struct_subj_seedvox = [];
review_subj_seedvox = [];
prose_subj_seedvox = [];

maskfile = '/home/zachkaras/fmri/analysis/atlases/MNI152_T1_2mm_brain_mask.nii.gz';
nii_template = load_untouch_nii(maskfile);

for f=1:numel(fnames)
    tic
    % Load and shape the data:
    disp(['subject ',num2str(f),' of ',num2str(numel(fnames)),' : ', fnames{f}]);
    rest_data = niftiread(fnames{f}); % load the data
    rest_data_2d = reshape(rest_data, numel(mask), size(rest_data,4)); % reshape it to 2D (voxels x timepoints)
    rest_data_2d_brain = rest_data_2d(brain_idx,:); % narrow it down to only the voxels in the brain mask (which importantly matches the size of the atlases!)
    % Analyze and save results:

    % If using seed regions:
    for i=1:numel(seed_masks_2d) % creates a seed ROIs x timepoints matrix of the average time series in each seed ROI
        seed_ts(i,:) = nanmean(rest_data_2d_brain(seed_masks_2d{i},:));
    end

    for i=1:numel(seed_masks_2d) % creates a seed ROIs x voxels matrix for the FC from each seed to each voxel
        [FC_seed2vox(i,:), FCp_seed2vox(i,:)] = corr(seed_ts(i,:)', rest_data_2d_brain','rows','pairwise','type','pearson');
    end


    if regexp(fnames{f}, '001')
        struct_subj_seedvox = cat(3, struct_subj_seedvox, FC_seed2vox);
    elseif regexp(fnames{f}, '002')
        review_subj_seedvox = cat(3, review_subj_seedvox, FC_seed2vox);
    elseif regexp(fnames{f}, '003')
        prose_subj_seedvox = cat(3, prose_subj_seedvox, FC_seed2vox);
    end
    toc    
end
% Z-transforming the data to make it normally distributed
struct_subj_seedvox(isnan(struct_subj_seedvox))=0;
review_subj_seedvox(isnan(review_subj_seedvox))=0;
prose_subj_seedvox(isnan(prose_subj_seedvox))=0;

struct_sub_seedvox_z = atanh(struct_subj_seedvox);
review_sub_seedvox_z = atanh(review_subj_seedvox);
prose_sub_seedvox_z = atanh(prose_subj_seedvox);

seed_vals = [8, 70, 74, 192, 271, 378, 396, 397];

plot_correlations(seed_masks_2d, seed_vals, struct_sub_seedvox_z, mni_brain, empty_brain, brain_idx, "struct")
plot_correlations(seed_masks_2d, seed_vals, review_sub_seedvox_z, mni_brain, empty_brain, brain_idx, "review")
plot_correlations(seed_masks_2d, seed_vals, prose_sub_seedvox_z, mni_brain, empty_brain, brain_idx, "prose")

% All studies together
super_brain = cat(3, struct_sub_seedvox_z, review_sub_seedvox_z, prose_sub_seedvox_z);

plot_correlations(seed_masks_2d, seed_vals, super_brain, mni_brain, empty_brain, brain_idx, "all")

% Mostly for getting t-stats and p-values
analyze_group_effects(struct_subj_seedvox, seed_masks_2d, seed_vals, brain_idx, mni_brain, nii_template, "struct");
analyze_group_effects(review_subj_seedvox, seed_masks_2d, seed_vals, brain_idx, mni_brain, nii_template, "review");
analyze_group_effects(prose_subj_seedvox, seed_masks_2d, seed_vals, brain_idx, mni_brain, nii_template, "prose");

%%
% Prose + Data Structures Study
novices = {'001_161', '003_150', '003_151', '003_203', '003_125', '001_151','001_153','001_154','001_158','001_162',...
    '001_166','001_167','001_170','001_175','003_119','003_121','003_130','003_131','003_133','003_134','003_140','003_142',...
    '003_144','003_112','003_141','001_155','001_160','001_165','001_173','003_105','003_109','003_118','003_122','003_129',...
    '003_138','003_143','003_147'};
experts = {'001_152', '001_156','001_157','001_163','001_174','001_177','001_178','001_181','001_182','001_183','003_101',...
    '003_102','003_108','003_111','001_159','001_168','001_176','001_180','003_201','001_172','001_201','001_171','001_203',...
    '001_169','001_179','001_200','001_202','001_204'};

% % Review validation test
% novices = {'002_302','002_339','002_322','002_351','002_325','002_329','002_340','002_310','002_320','002_336','002_338','002_305','002_416','002_330'};
% experts = {'002_345','002_314','002_311','002_328','002_412','002_403','002_406','002_411','002_306','002_315','002_400','002_404','002_300','002_409','002_327'};

% Trying novices, intermediate, experts
% novices = {'001_161','003_150','003_151','003_203','003_125','001_151','001_153','001_154','001_158','001_162','001_166',...
%     '001_167','001_170','001_175','003_119','003_121','003_130','003_131','003_133','003_134','003_140','003_142','003_144','003_112','003_141'};
% interms = {'001_155','001_160','001_165','001_173','003_105','003_109','003_118','003_122','003_129','003_138','003_143','003_147',...
%     '001_152','001_156','001_157','001_163','001_174','001_177','001_178','001_181','001_182','001_183','003_101','003_102','003_108','003_111'};
% experts = {'001_159','001_168','001_176','001_180','003_201','001_172','001_201','001_171','001_203','001_169','001_179','001_200','001_202','001_204'};


all_ids = regexprep(fnames, '_mc.nii.gz','');
nov_idx = find_group_members(novices, all_ids);
% int_idx = find_group_members(interms, all_ids);
exp_idx = find_group_members(experts, all_ids);

nov_connectivity = super_brain(:,:,nov_idx);
% int_connectivity = super_brain(:,:,int_idx);
exp_connectivity = super_brain(:,:,exp_idx);

n_nov = size(nov_connectivity,3);
% n_int = size(int_connectivity,3);
n_exp = size(exp_connectivity,3);

%% Writing Nifti files of experts, intermediates, and novices corresponding to each seed
for i=1:numel(seed_masks_2d)
    nov_vols = reshape_4d_nifti(n_nov, nov_connectivity(i,:,:), brain_idx, empty_brain);
    % int_vols = reshape_4d_nifti(n_int, int_connectivity(i,:,:), brain_idx, empty_brain);
    exp_vols = reshape_4d_nifti(n_exp, exp_connectivity(i,:,:), brain_idx, empty_brain);
    
    % write to nifti file for that seed
    % nov_int = cat(4, nov_vols, int_vols);
    nov_exp = cat(4, nov_vols, exp_vols);
    
    % % saving novice-intermediate, novice-expert nifti files, then
    % % compressing them
    % filename = sprintf("/home/zachkaras/fmri/midprocessing/nov_int_seed%d",seed_vals(i));
    % write_nii_cc(nii_template, nov_int, filename);
    % compress_file = sprintf("gzip /home/zachkaras/fmri/midprocessing/nov_int_seed%d.nii", seed_vals(i));
    % system(compress_file);

    filename = sprintf("/home/zachkaras/fmri/midprocessing/two_groups_nov_exp_seed%d",seed_vals(i));
    write_nii_cc(nii_template, nov_exp, filename);
    compress_file = sprintf("gzip /home/zachkaras/fmri/midprocessing/two_groups_nov_exp_seed%d.nii", seed_vals(i));
    system(compress_file);
end

% mni_slice = mni_brain(:,:,50);


%% Potentially outdated code for running t-tests and plotting output
for i=1:numel(seed_masks_2d)
    fprintf("Seed %d", seed_vals(i))
    nov_data = squeeze(nov_connectivity(i,:,:))';
    int_data = squeeze(int_connectivity(i,:,:))';
    exp_data = squeeze(exp_connectivity(i,:,:))';
    
    [~,expertise_pvals(i,:),~,expertise_stats(i,:)] = ttest2(exp_data,nov_data); % calculate t statistics
    % [~,expertise_pvals(i,:),~,expertise_stats(i,:)] = ttest2(int_data,nov_data); % calculate t statistics
    write_nii_cc(nii_template, expertise_stats(i,:), ['/home/zachkaras/fmri/results/three_groups_exp_v_nov',num2str(seedvals(i)),'.nii']); 
    % corrected_pvals = bonferroni(expertise_pvals(i,:));
    % 
    % test = filtered_stats > 0;
    % disp(sum(test))
    threshold = benjamini_hochberg(expertise_pvals(i,:));
    % [~,~,~, adj_p(i,:)] = mafdr(expertise_pvals(i,:), 'BHFDR', false);
    significant = expertise_pvals(i,:) < threshold;
    stats = expertise_stats(i).tstat;
    stats(~significant) = 0;
    % filtered_stats = expertise_stats(i).tstat(significant);
    % filtered_stats = expertise_stats(i,:).tstat;
    % filtered_stats(expertise_pvals(i,:) >= threshold) = 0;
    significant_mask = empty_brain;

    significant_mask(brain_idx) = stats; %expertise_pvals(i,:) < threshold;
    significant_mask = reshape(significant_mask, [91,109,91]);
    % significant_slice = significant_mask(:,:,50);
    % [rows, cols] = find(significant_slice);
    % d = cohens_d(exp_data, nov_data);
    
    plot_slices(seed_vals(i), significant_mask, mni_brain, "three_groups_exp_v_nov")
    
end


