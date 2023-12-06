%% Functional connectivity analysis guide

% Written by Ben Gold on September 5th, 2023

%% Note: this script uses the shapes study data as an example. Change relevant directories/filenames to other datasets as needed.

%% Initialization

% First, put all of the preprocessed fMRI files for a single study in one folder, e.g., /storage2/fmridata/fmri-data-shapes/fmri-scans/rest_preprocessed/
% The contents of that folder should be along the lines of "sub1_preproc.nii," "sub2_preproc.nii," etc. -- subject files to analyze and nothing else!

% Go to the data:
% cd('/storage2/fmridata/fmri-data-shapes/fmri-scans/rest_preprocessed'); % CHANGE THIS to the data directory with the preprocessed fMRI data
% cd('mnt/codeprose/preprocessed/')
datapath = 'mnt/motion_corrected/';
files = dir(datapath); for i=3:numel(files); fnames{i-2}=files(i).name; end % find the file names to analyze in the current directory

% Next, make sure that you have a brain mask file and any results or atlas files you want to use to identify seed regions
% Load a brain mask to limit analyses:
maskfile = 'mnt/analysis/atlases/MNI152_T1_2mm_brain_mask.nii.gz'; % change the path as needed
mask = niftiread(maskfile); % loads the full 91x109x91 mask
brain_idx = find(mask>0); % identifies only the voxels of the brain

% Load and create an empty template image for writing NIfTI files:
nii_template = load_untouch_nii(maskfile); % load the brain mask for an example in the right (91x109x91) space
nii_template.img = zeros(size(nii_template.img)); % replace the mask with all 0s
empty_brain = nii_template.img; % create an empty_brain image in the template's shape

% Load any results files or atlases, in 91x109x91 space, if desired (i.e., if not doing a voxel-by-voxel analysis):
% Here are two example atlases I suggest (ADD THESE to the fmridata directory first!):
cortex_atlas = niftiread('mnt/analysis/atlases/Schaefer2018_400Parcels_7Networks_order_FSLMNI152_2mm.nii.gz'); % from https://github.com/ThomasYeoLab/CBIG/tree/master/stable_projects/brain_parcellation/Schaefer2018_LocalGlobal/Parcellations/MNI
cortex_labels = readtable('mnt/analysis/atlases/Schaefer2018_400Parcels_7Networks_order.lut','ReadVariableNames',0,'FileType','text');
for i=1:size(cortex_labels,1) % if doing network (as opposed to just region-based) analyses, derive a list of network identities from the labels of the networks and regions:
    temp = split(cortex_labels.Var5{i}, '_');
    temp = temp{3};
    network_labels{i}=temp; % this only works with the specifics of the Schaefer atlas labels: adapt as needed
end
all_cortex_network_labels=unique(network_labels);

subcortex_atlas = niftiread('mnt/analysis/atlases/Tian_Subcortex_S1_3T.nii'); % from https://github.com/yetianmed/subcortex/tree/master/Group-Parcellation/3T/Subcortex-Only
subcortex_labels = readtable('mnt/analysis/atlases/Tian_Subcortex_S1_3T_label.txt','ReadVariableNames',0); % for this particular atlas, only the region names are given (because they're all within the subcortex)

roi_labels = [cortex_labels.Var5; subcortex_labels]; % here I combine the two atlases, with the cortex first and subcortex second, to use both of them together

% These two atlases happen to have some overlap, though, so here I trim back the subcortex atlas to exclude voxels assigned to the cortex one:
cortex_2d_brain = cortex_atlas(brain_idx); % reshape to 2D
subcortex_2d_brain = subcortex_atlas(brain_idx); % reshape to 2D
subcortex_2d_brain(cortex_2d_brain & subcortex_2d_brain)=0; % change the voxels in the subcortical atlas that overlap with those in the cortical atlas to 0s

% Add to the values in the subcortical atlas so that each cortical and subcortical region has its own value:
subcortex_2d_brain(subcortex_2d_brain>0) = subcortex_2d_brain(subcortex_2d_brain>0) + (numel(unique(cortex_2d_brain)) - 1); % subtract 1 here because one of the values in the cortical atlas is 0 (for no region)
atlas_2d_brain = cortex_2d_brain + subcortex_2d_brain;

% Now separate out the indices of each region from this combined atlas to analyze them separately:
for i=1:(numel(unique(atlas_2d_brain))-1) % excludes 0s
    roi_masks_2d{i} = find(atlas_2d_brain==i);
end

% Now separate out the indices of each network from this combined atlas to analyze them separately:
for i=1:numel(all_cortex_network_labels)
    net_rois=find(strcmp(network_labels,all_cortex_network_labels{i}));
    net_masks_2d{i}=[];
    for j=1:numel(net_rois)
        net_masks_2d{i} = [net_masks_2d{i}; find(atlas_2d_brain==net_rois(j))];
    end
    clear net_rois;
end

net_masks_2d{numel(all_cortex_network_labels)+1} = []; % add another network (the subcortex) from the other (Tian et al.) atlas:
net_rois = numel(unique(cortex_2d_brain)):(numel(unique(atlas_2d_brain))-1);
for j=1:numel(net_rois)
    net_masks_2d{numel(all_cortex_network_labels)+1} = [net_masks_2d{numel(all_cortex_network_labels)+1}; find(atlas_2d_brain==net_rois(j))];
end
all_cortex_network_labels{end+1}='Subcortex';

% Here's an example of a result/seed that you might use:
result_map = niftiread('mnt/analysis/atlases/Schaefer2018_400Parcels_7Networks_order_FSLMNI152_2mm.nii.gz'); % let's pretend this is a result or seed region file
result_map_2d_brain = result_map(brain_idx); % reshapes to 2d within the brain

% now let's pretend that we want to use three seed regions, which have the values of 1, 2, and 3 in the brain:
% seed_vals = [1,2,3];
%seed_vals = [8, 17, 71, 136, 209, 216, 309, 376];
seed_vals = [8, 70, 74, 192, 271, 378, 396, 397];
for i=1:numel(seed_vals)
    seed_masks_2d{i} = find(result_map_2d_brain == seed_vals(i));
end

%% Analyze each subject:
for f=1:numel(fnames)
    tic
    % Load and shape the data:
    disp(['subject ',num2str(f),' of ',num2str(numel(fnames)),':', fnames{f}]);
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
    subj_seedvox(:,:,f) = FC_seed2vox; % save the results
    toc
    % [FC_seed2seed, FCp_seed2seed] = corr(seed_ts','rows','pairwise','type','pearson'); % creates a seed ROIs x seed ROIs matrix for the FC from each seed to each other seed (e.g., for measuring the FC between the regions activated during the task)
    % allsubs_FC_seed2seed(:,:,f) = FC_seed2seed; % save the results
    
    % % If using ROIs (which are essentially seeds):
    % for i=1:numel(roi_masks_2d) % creates an ROIs x timepoints matrix of the average time series in each ROI
    %     roi_ts(i,:) = nanmean(rest_data_2d_brain(roi_masks_2d{i},:));
    % end
    % 
    % [FC_roi2roi, FCp_roi2roi] = corr(roi_ts','rows','pairwise','type','pearson'); % creates an ROIs x ROIs matrix for the FC from each ROI to each other ROI
    % allsubs_FC_roi2roi(:,:,f) = FC_roi2roi; % save the results
    % 
    % % If using networks:
    % for i=1:numel(net_masks_2d) % creates a networks x timepoints matrix of the average time series in each network
    %     net_ts(i,:) = nanmean(rest_data_2d_brain(net_masks_2d{i},:));
    % end
    % 
    % [FC_net2net, FCp_net2net] = corr(net_ts','rows','pairwise','type','pearson'); % creates a network x network matrix for the FC from each network to each other network
    % allsubs_FC_net2net(:,:,f) = FC_net2net; % save the results
    
end
clear rest_data
save('12032023.mat')
    
%% Analyze group effects:
% You could analyze the FC data in many ways. Here are a few ideas.
% If using seed regions:
subj_seedvox_z = atanh(allsubs_FC_seed2vox); % use Fisher's z transformation to make the correlation coefficients follow a more normal distribution (if wanted)

% Evaluate the group-level effect of the FC from each seed to each voxel (e.g., to visualize results):
for i=1:numel(seed_masks_2d)
    [~,pvals(i,:),~,stats(i,:)] = ttest(squeeze(subj_seedvox_z(i,:,:))',0); % calculate t statistics
    
    % Save the resulting t statistics to a brain image in a NIfTI file for hypothesis testing and visualization:
    % significant_voxels = benjamini_hochberg(pvals(i,:));
    % significant_voxels = bonferroni(pvals(i,:));
    
    % grp_seedvox_t(brain_idx) = stats(i).tstat;
    % grp_seedvox_t(~significant_voxels) = 0;
    grp_seedvox_t = empty_brain;
    grp_seedvox_t(brain_idx) = stats(i).tstat;

    % break
    write_nii_cc(nii_template, grp_seedvox_t, ['local_results/grp_seedvox',num2str(seed_vals(i)),'_t.nii']);
    compress_file = sprintf("gzip local_results/grp_seedvox%d_t.nii", seed_vals(i));
    system(compress_file);
end

novices = {'105' '108' '111' '119' '125' '138' '140' '144' '150'};
experts = {'121' '122' '129' '131' '141' '142' '151' '201' '203'};
all_ids = regexprep(fnames, '_mc.nii.gz','');
nov_idx = find_group_members(novices, all_ids);
exp_idx = find_group_members(experts, all_ids);

nov_connectivity = subj_seedvox_z(:,:,nov_idx);
exp_connectivity = subj_seedvox_z(:,:,exp_idx);

for i=1:numel(seed_masks_2d)
    [~,expertise_pvals(i,:),~,expertise_stats(i,:)] = ttest(squeeze(exp_connectivity(i,:,:))',squeeze(nov_connectivity(i,:,:))'); % calculate t statistics
    expertise_t_stats = empty_brain;
    expertise_t_stats(brain_idx) = stats(i).tstat;
    write_nii_cc(nii_template, expertise_t_stats, ['local_results/expertise_seed',num2str(seed_vals(i)),'_t.nii']);
    compress_file = sprintf("gzip local_results/expertise_seed%d_t.nii", seed_vals(i));
    system(compress_file);
end

test_brain = niftiread('local_results/expertise_seed397_t.nii.gz');
test_slice = test_brain(:,:,50);

figure
imshow(test_slice, [])
colormap(jet);
% clim([0 60]);
title("Test", 'FontSize', 18)
set(gcf, 'Position', [100, 100, 800, 600])

% Compare individual differences in FC to individual differences in other subject-level measures like task performance, coding experience, etc.:
behavdata = readtable('/storage2/fmridata/fmri-data-shapes/surveydata.csv'); % CHANGE THIS as needed

for i=1:numel(seed_masks_2d) % CHANGE THE BEHAVIORAL VARIABLE as needed
    [r_FC_behav_seed2roi(i,:),p_FC_behav_seed2roi(i,:)] = corr(behavdata.experience, squeeze(subj_seedvox_z(i,:,:))','rows','pairwise','type','pearson');
        
    % Save the resulting correlation statistics to a brain image in a NIfTI file for hypothesis testing and visualization:
    grp_FC_behav_r = empty_brain;
    grp_FC_behav_r(brain_idx) = r_FC_behav_seed2roi(i);
    write_nii_cc(nii_template, grp_FC_behav_r, ['/storage2/fmridata/fmri-data-shapes/fmri-scans/rest_results/grp_seed2vox_FC_behav_seed',num2str(i),'_r.nii']); 
end




% If using atlas ROIs:
zFC_roi2roi = atanh(allsubs_FC_roi2roi); % use Fisher's z transformation to make the correlation coefficients follow a more normal distribution (if wanted)
for i=1:size(zFC_roi2roi,1); zFC_roi2roi(i,i,:) = NaN; end % set all diagonal elements to NaN (since they're autocorrelations anyway)

% Evaluate the group-level effect of the FC from each ROI to each other ROI (e.g., to visualize results):
[~,pFC_roi2roi,~,statsFC_roi2roi] = ttest(zFC_roi2roi,0,'dim',3);
figure; imagesc(nanmean(zFC_roi2roi,3)); colorbar; title('Group-averaged FC (z scores)'); % to visualize the average ROI-to-ROI FC
figure; imagesc(pFC_roi2roi); colorbar; title('Group-level FC significance ({\itp} values)'); % to visualize the uncorrected t test p values of ROI-to-ROI FC
% You can then reference roi_labels to identify the regions

% Compare individual differences in FC to individual differences in other subject-level measures like task performance, coding experience, etc.:
behavdata = readtable('/storage2/fmridata/fmri-data-shapes/surveydata.csv'); % CHANGE THIS as needed

for i=1:numel(roi_labels) % CHANGE THE BEHAVIORAL VARIABLE as needed
        [r_FC_behav_roi2roi(i,:),p_FC_behav_roi2roi(i,:)] = corr(behavdata.experience, squeeze(zFC_roi2roi(i,:,:))','rows','pairwise','type','pearson');
end
figure; imagesc(r_FC_behav_roi2roi); colorbar; title('FC vs. Experience (Pearson''s {\itr})'); % to visualize correlations between the behavioral measure and ROI-to-ROI FC
figure; imagesc(p_FC_behav_roi2roi); colorbar; title('FC vs. Experience (uncorrected {\itp})'); % to visualize the uncorrected p values
% NOTE that these are symmetrical matrices, and their diagonals are undefined (NaN). So if there are 416 ROIs, that's (416*415)/2 parallel tests
% You can then reference roi_labels to identify the regions



% If using atlas networks:
zFC_net2net = atanh(allsubs_FC_net2net); % use Fisher's z transformation to make the correlation coefficients follow a more normal distribution (if wanted)
for i=1:size(zFC_net2net,1); zFC_net2net(i,i,:) = NaN; end % set all diagonal elements to NaN (since they're autocorrelations anyway)

% Evaluate the group-level effect of the FC from each network to each other network (e.g., to visualize results):
[~,pFC_net2net,~,statsFC_net2net] = ttest(zFC_net2net,0,'dim',3);
figure; imagesc(nanmean(zFC_net2net,3)); colorbar; title('Group-averaged FC (z scores)'); % to visualize the average network-to-network FC
set(gca,'xtick',1:numel(all_cortex_network_labels)); set(gca,'xticklabel',all_cortex_network_labels); xtickangle(45); set(gca,'ytick',1:numel(all_cortex_network_labels)); set(gca,'yticklabel',all_cortex_network_labels);
figure; imagesc(pFC_net2net); colorbar; title('Group-level FC significance ({\itp} values)'); % to visualize the uncorrected t test p values of network-to-network FC
set(gca,'xtick',1:numel(all_cortex_network_labels)); set(gca,'xticklabel',all_cortex_network_labels); xtickangle(45); set(gca,'ytick',1:numel(all_cortex_network_labels)); set(gca,'yticklabel',all_cortex_network_labels);
% NOTE that these are symmetrical matrices, and their diagonals are undefined (NaN). So if there are 8 networks, that's (8*7)/2 parallel tests

% Compare individual differences in FC to individual differences in other subject-level measures like task performance, coding experience, etc.:
behavdata = readtable('/storage2/fmridata/fmri-data-shapes/surveydata.csv'); % CHANGE THIS as needed

for i=1:numel(all_cortex_network_labels) % CHANGE THE BEHAVIORAL VARIABLE as needed
    [r_FC_behav_net2net(i,:),p_FC_behav_net2net(i,:)] = corr(behavdata.experience, squeeze(zFC_net2net(i,:,:))','rows','pairwise','type','pearson');
end
figure; imagesc(r_FC_behav_net2net); colorbar; title('FC vs. Experience (Pearson''s {\itr})'); % to visualize correlations between the behavioral measure and network-to-network FC
set(gca,'xtick',1:numel(all_cortex_network_labels)); set(gca,'xticklabel',all_cortex_network_labels); xtickangle(45); set(gca,'ytick',1:numel(all_cortex_network_labels)); set(gca,'yticklabel',all_cortex_network_labels);
figure; imagesc(p_FC_behav_net2net); colorbar; title('FC vs. Experience (uncorrected {\itp})'); % to visualize the uncorrected p values
set(gca,'xtick',1:numel(all_cortex_network_labels)); set(gca,'xticklabel',all_cortex_network_labels); xtickangle(45); set(gca,'ytick',1:numel(all_cortex_network_labels)); set(gca,'yticklabel',all_cortex_network_labels);
% NOTE that these are symmetrical matrices, and their diagonals are undefined (NaN). So if there are 8 networks, that's (8*7)/2 parallel tests




