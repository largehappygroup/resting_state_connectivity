%% Nuisance Regression
% Reads in motion parameters from each participant
% then regresses them out of the signal at each voxel
% saves a clean functional file in data/clean

% for loop iterating through participants in preprocessed folder
datapath = "./data/midprocess";
files = dir(datapath); for i=3:numel(files); fnames{i-2}=files(i).name; end

for i=1:numel(fnames)
    tic
    if isempty(regexp(fnames{i}, 'out'))
        continue
    end
    disp(i)
    disp(fnames{i})
    name = fnames{i};
    name = regexp(fnames{i}, '.nii.gz', 'split');
    name = name{1};
    
    fprintf("regressing out nuisances for %s\n", name)
    if contains(fnames{i}, '001') || contains(fnames{i}, '003')
        brain_path = sprintf("./data/midprocess/%s/filtered_func_data_clean.nii.gz", name);
        motion_filepath = sprintf("./data/midprocess/%s/mc/prefiltered_func_data_mcf.par", name);
    elseif contains(fnames{i}, '002') || contains(fnames{i}, '101')
        brain_path = sprintf("./data/midprocess/%s/filtered_func_data.nii.gz", name);
        % find motion parameters file
        motion_filepath = sprintf("./data/midprocess/%s/st_mc.nii.par", name);
    end
    
    % disp(brain_path)
    disp("reading nifti file")
    brain_data = niftiread(brain_path);
    length = size(brain_data,4);

    % design matrix and data
    disp("creating design matrix")
    X = make_design_matrix(motion_filepath, length);
    Y = reshape(brain_data, [(91*109*91),length])';

    % fitting parameters to brain signal
    disp("removing noise")
    b = X\Y;
    Yhat = X*b;
    YC = Y-Yhat;
    YC = reshape(YC', [91,109,91,length]);     

    disp("saving")
    outfile = sprintf("./data/clean/%s", name(5:end));
    disp(outfile)
    niftiwrite(YC, outfile);
    compress_file = sprintf("gzip ./data/clean/%s.nii", name(5:end));
    system(compress_file);
    toc
    % break

end

function X = make_design_matrix(path, length)
    % mean offset, linear, and quadratic trends
    % n = 600; % num volumes
    mean_offset = ones(length,1);
    linear_trend = (1:length)';
    % quad_trend = (1:n)'.^2;

    % load parameters (clip to 600 volumes)
    Motion = importdata(path);
    Motion = Motion(1:length, :);
    dMP = diff(Motion);
    dMP = [dMP(1,:); dMP];

    % removed quadratic trend because all the timecourses turned into parabolas
    X = [mean_offset, linear_trend, Motion, dMP]; 
end

