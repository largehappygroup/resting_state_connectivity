% for loop iterating through participants in preprocessed folder
datapath = "home/zachkaras/fmri/preprocessed/";
files = dir(datapath); for i=3:numel(files); fnames{i-2}=files(i).name; end

for i=1:numel(fnames)
    tic
    name = regexp(fnames{i}, '.nii.gz', 'split');
    name = name{1};
    
    fprintf("regressing out nuisances for %s\n", name)

    brain_path = sprintf("home/zachkaras/fmri/preprocessed/%s.nii.gz", name);
    disp(brain_path)
    brain_data = niftiread(brain_path);

    % find motion parameters file
    motion_filepath = sprintf("home/zachkaras/fmri/three_studies_raw/%s/st_mc.nii.par", name);
    disp(motion_filepath)

    % design matrix and data
    X = make_design_matrix(motion_filepath);
    Y = reshape(brain_data, [(91*109*91),600])';

    % fitting parameters to brain signal
    b = X\Y;
    Yhat = X*b;
    YC = Y-Yhat;
    YC = reshape(YC', [91,109,91,600]);     
    
    outfile = sprintf("home/zachkaras/fmri/motion_corrected/%s_mc", name(5:end));
    disp(outfile)
    niftiwrite(YC, outfile);
    compress_file = sprintf("gzip home/zachkaras/fmri/motion_corrected/%s_mc.nii", name(5:end));
    system(compress_file);
    toc
%     break

end

function X = make_design_matrix(path)
    % mean offset, linear, and quadratic trends
    n = 600; % num volumes
    mean_offset = ones(n,1);
    linear_trend = (1:n)';
    quad_trend = (1:n)'.^2;

    % load parameters (clip to 600 volumes)
    Motion = importdata(path);
    Motion = Motion(1:600, :);
    dMP = diff(Motion);
    dMP = [dMP(1,:); dMP];

    X = [mean_offset, linear_trend, quad_trend, Motion, dMP];
end
