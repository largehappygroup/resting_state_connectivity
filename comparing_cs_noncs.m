% Comparing CS Students with non-CS Students
datapath = '/home/zachkaras/fmri/preprocessed2/';
files = dir(datapath); for i=3:numel(files); fnames{i-2}=files(i).name; end % find the file names to analyze in the current directory

review_subj_seedvox = [];
noncs_subj_seedvox = [];
review_ds_subj_seedvox = [];

maskfile = '/home/zachkaras/fmri/analysis/atlases/MNI152_T1_2mm_brain_mask.nii.gz';
nii_template = load_untouch_nii(maskfile);

seed_vals = [58,133,192,339,377,395];

for f=38:numel(fnames)
    tic
    % Load and shape the data:
    disp(['subject ',num2str(f),' of ',num2str(numel(fnames)),' : ', fnames{f}]);
    rest_data = niftiread(fnames{f}); % load the data
    rest_data_2d = reshape(rest_data, numel(mask), size(rest_data,4)); % reshape it to 2D (voxels x timepoints)
    rest_data_2d_brain = rest_data_2d(brain_idx,:); % narrow it down to only the voxels in the brain mask (which importantly matches the size of the atlases!)
    % Analyze and save results:
    
    seed_ts = [];
    % If using seed regions:
    for i=1:numel(seed_masks_2d) % creates a seed ROIs x timepoints matrix of the average time series in each seed ROI
        seed_ts(i,:) = nanmean(rest_data_2d_brain(seed_masks_2d{i},:));
    end

    for i=1:numel(seed_masks_2d) % creates a seed ROIs x voxels matrix for the FC from each seed to each voxel
        [FC_seed2vox(i,:), FCp_seed2vox(i,:)] = corr(seed_ts(i,:)', rest_data_2d_brain','rows','pairwise','type','pearson');
    end


    if regexp(fnames{f}, '101')
        noncs_subj_seedvox = cat(3, noncs_subj_seedvox, FC_seed2vox);
    elseif regexp(fnames{f}, '002')
        review_subj_seedvox = cat(3, review_subj_seedvox, FC_seed2vox);
    elseif regexp(fnames{f}, '102')
        review_ds_subj_seedvox = cat(3, review_ds_subj_seedvox, FC_seed2vox);
    end
    toc    
end
% Z-transforming the data to make it normally distributed
noncs_subj_seedvox(isnan(noncs_subj_seedvox))=0;
review_subj_seedvox(isnan(review_subj_seedvox))=0;
review_ds_subj_seedvox(isnan(review_ds_subj_seedvox))=0;

noncs_subj_seedvox_z = atanh(noncs_subj_seedvox);
review_subj_seedvox_z = atanh(review_subj_seedvox);
review_ds_subj_seedvox_z = atanh(review_ds_subj_seedvox);


plot_correlations(seed_masks_2d, seed_vals, noncs_subj_seedvox_z, mni_brain, empty_brain, brain_idx, "noncs")
plot_correlations(seed_masks_2d, seed_vals, review_sub_seedvox_z, mni_brain, empty_brain, brain_idx, "review")
plot_correlations(seed_masks_2d, seed_vals, review_ds_subj_seedvox_z, mni_brain, empty_brain, brain_idx, "review_ds")

% All studies together
super_brain = cat(3, struct_sub_seedvox_z, prose_sub_seedvox_z); % leaving out review



