%% Functional Connectivity: Data Loading

% Loading atlases 
% Loading a brain mask file and the atlas files for identifying seed regions
maskfile = 'atlases/MNI152_T1_2mm_brain_mask.nii.gz';
mask = niftiread(maskfile); % loads the full 91x109x91 mask
mni_brain_file = 'atlases/MNI152_T1_2mm_brain.nii.gz';
mni_brain = niftiread(mni_brain_file);
brain_idx = find(mask>0); % identifies only the voxels of the brain, not the empty space

% Loading and create an empty template image for writing NIfTI files:
nii_template = load_untouch_nii(maskfile); % load the brain mask for an example in the right (91x109x91) space
nii_template.img = zeros(size(nii_template.img)); % replace the mask with all 0s
empty_brain = nii_template.img; % create an empty_brain image in the template's shape

atlas = niftiread('./atlases/Schaefer2018_400Parcels_7Networks_order_FSLMNI152_2mm.nii.gz'); % let's pretend this is a result or seed region file
atlas_2d_brain = atlas(brain_idx); % reshapes to 2d within the brain

% Loading fMRI data
datapath = 'data/clean';
files = dir(datapath); for i=3:numel(files); filenames{i-2}=files(i).name; end % find the file names to analyze in the current directory

for i=1:400 % iterating through Schaefer atlas to get indices for each parcel
    parcels{i} = find(atlas_2d_brain == i);
end

seed_vals = [133,172,192,284,339,395]; 
% Data driven seed values
% seed_vals = [9,67,176,183,231,242,341,343,348,380,386,389,391]; 

for i=1:numel(seed_vals) % Finds indices specific to each seed region
    seed_masks_2d{i} = find(atlas_2d_brain == seed_vals(i));
end

%% Main loop for computing functional connectivity (FC)
% for every participant, first calculates average timecourse of each parcel
% then calculates FC from every parcel to every other parcel
% saves into a large matrix that stores all participants' FC data
a_parcels = []; % Dataset A (non-programmers)
b_parcels = []; % Dataset B (programmers)
c_parcels = [];
d_parcels = [];

for f=1:numel(filenames) 
    tic

    % Loading and shaping current participant's data
    disp(['subject ',num2str(f),' of ',num2str(numel(filenames)),':', filenames{f}]);
    restdata = niftiread(filenames{f}); % loading the data
    restdata_2d = reshape(restdata, numel(mask), size(restdata,4)); % reshaping it to 2D (voxels x timepoints)
    restdata_2d_brain = restdata_2d(brain_idx,:); % narrowing it down to only the voxels in the brain mask
    
    % calculating average timecourse for each seed region
    timecourses = [];
    for i=1:numel(parcels) % creates a seed ROIs x timepoints matrix of the average time series in each seed ROI
        timecourses(i,:) = nanmean(restdata_2d_brain(parcels{i},:));
    end
    
    % These group specific timecourses are used to calculate in-group 
    % correlations (i.e., connectivity patterns for non-programmers)
    if contains(filenames{f}, '101_') % Dataset A: non-programmers
        a_parcels = cat(3, a_parcels, timecourses);
    elseif contains(filenames{f}, '002_') % Dataset B: programmers
        b_parcels = cat(3, b_parcels, timecourses);
    elseif contains(filenames{f}, '001_') % Dataset C
        c_parcels = cat(3, c_parcels, timecourses);
    elseif contains(filenames{f}, '003_') % Dataset D
        d_parcels = cat(3, d_parcels, timecourses);
    end

    % Actual code for calculating FC
    for s=1:numel(seed_vals)
        seed_timecourse = timecourses(seed_vals(s),:);

        % Correlations_noncs is used for calculating statistical differences between groups
        [Correlations_noncs(f,:,s), p_vals_noncs(f,:,s)] = corr(seed_timecourse', timecourses', 'rows', 'pairwise', 'type','pearson');      
    end

    % clearing variables that take up a lot of space
    clear restdata restdata_2d restdata_2d_brain 
    toc
end

% removing undefined values from correlations
Correlations_noncs(isnan(Correlations_noncs))=0;

%% Reformatting/Organizing Data
calculate_group_connectivity(a_parcels, 'a');
calculate_group_connectivity(b_parcels, 'b');
calculate_group_connectivity(c_parcels, 'c');
calculate_group_connectivity(d_parcels, 'd');

a_connectivity = Correlations_noncs(4,:,:);
a_connectivity = atanh(a_connectivity);

b_connectivity = Correlations_noncs(2,:,:);
b_connectivity = atanh(b_connectivity);

c_connectivity = Correlations_noncs(1,:,:);
c_connectivity = atanh(c_connectivity);

d_connectivity = Correlations_noncs(3,:,:);
d_connectivity = atanh(d_connectivity);


function calculate_group_connectivity(parcels, groupname)
    parcels(isnan(parcels)) = 0; % removing undefined values
    mean_mat = mean(parcels, 3); % calculating mean values of group timecourses
    grp_corr = corr(mean_mat'); % correlations between parcel timecourses
    corr_z = atanh(grp_corr); % Fisher's Z-transformation
    outpath = sprintf("./sample_results/dataset_%s_corr_z.csv",groupname); % saving results
    writematrix(corr_z, outpath)
end
