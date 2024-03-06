% create average time courses for each parcel in Schaefer atlas

% loading participant data
datapath = '/home/zachkaras/fmri/preprocessed/';
files = dir(datapath); for i=3:numel(files); fnames{i-2}=files(i).name; end % find the file names to analyze in the current directory

% mask files / important variables
maskfile = '/home/zachkaras/fmri/analysis/atlases/MNI152_T1_2mm_brain_mask.nii.gz'; % change the path as needed
mask = niftiread(maskfile); % loads the full 91x109x91 mask
brain_idx = find(mask>0); % identifies only the voxels of the brain

atlas = niftiread('/home/zachkaras/fmri/analysis/atlases/Schaefer2018_400Parcels_7Networks_order_FSLMNI152_2mm.nii.gz'); % let's pretend this is a result or seed region file
atlas_2dbrain = atlas(brain_idx); % reshapes to 2d within the brain

% iterate through Schaefer atlas to get indices for each parcel
for i=1:400
    parcels{i} = find(atlas_2dbrain == i);
end

seed_vals = [58,133,192,339,377,395]; % Updated 3/3/20204

% for i=1:numel(seed_vals)
%     seed_masks_2d{i} = find(atlas_2dbrain == seed_vals(i));
% end


for f=1:numel(fnames)
    tic
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

    for s=1:numel(seed_vals)
        seed_timecourse = timecourses(seed_vals(s),:);
        [Correlations(f,:,s), p_vals(f,:,s)] = corr(seed_timecourse', timecourses', 'rows', 'pairwise', 'type','pearson');
        
    end
    toc
end

for i=1:numel(seed_vals)
    outfilename = sprintf("/home/zachkaras/fmri/midprocessing/correlations_seed%d.csv", seed_vals(i));
    writematrix(Correlations(:,:,i), outfilename);
end


% for p=1:numel(fnames)
%     Correlations2(p,:,:) = atanh(Correlations(p,:,:));
%     % Correlations2(p,:,:) = Correlations2(p,:,:) - nanmean(Correlations2(p,:,:));
% end

% zero mean and atanh for each participant
